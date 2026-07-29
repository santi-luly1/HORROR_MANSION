/*
[=[
    @class RoundService
    @author santi-luly1
    @description Main server game loop handler

    CHANGELOG: [
        26/01/21 --> Initial version of the module.
        26/01/28 --> Adjusted to the new KillerService and added checks for in-progress rounds.
        26/02/02 --> Display survivors on a Message instance.
        26/02/14 --> If the killer dies, now the round ends with a message, and better hint message.
        26/02/16 --> Better script performance.
        26/03/01 --> Added points rewards once the round ended, signals for round end and start, and GetIntermissionTimeout API.
        26/03/13 --> Added IsEnding guard to block round starts during teardown (AI).
        26/03/15 --> Parsed into roblox-ts.
		26/07/16 --> Implemented logger.
    ]
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
// Roblox services
import { Debris, Players, RunService, Workspace } from "@rbxts/services";

// Packages
import { Service, OnInit, OnStart } from "@flamework/core";
import { Trove } from "@rbxts/trove";
import { debug, info, warn } from "@rbxts/logger";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";

// Types
import { Killer } from "server/types/KillerService";

// Networking

// Local utilities

// Services
import KillerService from "./KillerService";
import PlayerDataService from "./PlayerDataService";

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export default class RoundServiceClass implements OnInit, OnStart {
	/*
		state
	*/
	private inProgress = false;
	private isEnding = false;

	/*
		runtime fields
	*/
	public RoundStarted = new Signal<(preferredKiller: string) => void>();
	public RoundEnded = new Signal<(skipped: boolean) => void>();
	private trove = new Trove();

	/*
	--------------------------------------------------------------------
	--- Constructor
	--------------------------------------------------------------------
	*/
	constructor(private readonly KillerService: KillerService, private readonly PlayerDataService: PlayerDataService) {}

	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/
	// private countdownHint = new Instance("Hint"); // TODO: Since this is deprecated, I'll have to make them into a gui notification
	public static readonly TOTAL_ROUND_DURATION = RunService.IsStudio() ? 15 : 120;
	public static readonly ANNOUNCEMENT_LIFETIME = 3;
	public static readonly INTERMISSION_TIMEOUT = 10;
	public static readonly DEFAULT_PREFERRED_KILLER = "**";

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public onInit() {}

	public onStart() {
		// start the main loop.
		// delay just to wait for any other loading service
		task.delay(10, () => this.Begin("Hacker"));
	}

	/*
	--------------------------------------------------------------------
	--- Private Methods
	--------------------------------------------------------------------
	*/
	private async startRound(preferredKiller: string): Promise<Killer[]> {
		return new Promise((resolve, reject, onCancel) => {
			if (this.inProgress) {
				warn(
					`[${script.Name}] startRound called while already in progress (preferredKiller=${preferredKiller})`,
				);
				return reject("Round already in progress");
			}

			this.inProgress = true;
			debug(`[${script.Name}] Round started (preferredKiller=${preferredKiller})`);
			this.RoundStarted.Fire(preferredKiller);

			let cancelled = false;
			if (
				onCancel(() => {
					cancelled = true;
					this.cleanupRound();
				})
			)
				return;

			let killersToSpawn: string;

			if (preferredKiller === "*") {
				killersToSpawn = "*";
			} else if (preferredKiller === RoundServiceClass.DEFAULT_PREFERRED_KILLER) {
				const candidates: string[] = this.KillerService.GetKillersName(false);
				killersToSpawn = candidates[math.random(1, candidates.size())]; // as of now, there are is only one killer spawn per round, next update to make it be more than one.
			} else {
				killersToSpawn = preferredKiller;
			}

			debug(`[${script.Name}] Spawning killers (killersToSpawn=${killersToSpawn})`);

			const spawnPromise =
				killersToSpawn !== "*"
					? this.KillerService.SpawnKillers([killersToSpawn], -1)
					: this.KillerService.SpawnAll(-1);

			spawnPromise
				.andThen((initialKillers) => {
					if (cancelled) {
						debug(`[${script.Name}] startRound cancelled after spawnPromise resolved`);
						return;
					}

					if (initialKillers.size() === 0) {
						warn(`[${script.Name}] No killers spawned`);
						this.cleanupRound();
						return reject("No killers spawned");
					}

					this.trove.add(
						this.KillerService.KillerCleared.Connect((killer) => {
							if (this.isEnding || !this.inProgress) return;

							task.defer(() => {
								const remaining = this.KillerService.GetCurrentKillers();
								if (remaining.size() < 1 && !this.isEnding) {
									// it was the last killer, so time for cleanup.
									info(`[${script.Name}] Last killer cleared, stopping round`);
									this.Stop();
								} else {
									debug(`[${script.Name}] Killer cleared: ${killer}`);
									// TODO: Since this is deprecated, I'll have to make them into a gui notification
									print(`${killer} has been killed.`);
								}
							});
						}),
					);

					this.trove.add(
						task.spawn(() => {
							let countdown = RoundServiceClass.TOTAL_ROUND_DURATION;
							const cachedNames: string[] = [];
							let cachedCount = -1;
							let killerCount = 0;

							const updateCache = () => {
								const currentKillers = this.KillerService.GetCurrentKillers();
								killerCount = currentKillers.size();

								if (killerCount !== cachedCount) {
									cachedCount = killerCount;
									cachedNames.clear();
									for (const k of currentKillers) cachedNames.push(k.name);
								}
							};

							// invalidate cache when new killers spawn
							this.trove.add(this.KillerService.KillerSpawned.Connect(() => (cachedCount = -1)));

							while (countdown >= 0 && this.inProgress && !this.isEnding) {
								updateCache();

								if (killerCount === 0) {
									warn(`[${script.Name}] No killers during countdown`);
									print("No killers.");
									task.wait(3);
									break;
								} else if (killerCount === 1) {
									debug(`[${script.Name}] ${cachedNames[0]} leaves in ${countdown}s`);
									print(`${cachedNames[0]} leaves in ${countdown}s`);
								} else {
									if (killerCount > 5) {
										debug(`[${script.Name}] ${killerCount} killers will leave in ${countdown}s`);
										print(`${killerCount} killers will leave in ${countdown}s`);
									} else {
										debug(
											`[${script.Name}] ${cachedNames.join(", ")} will leave in ${countdown}s.`,
										);
										print(`${cachedNames.join(", ")} will leave in ${countdown}s.`);
									}
								}

								task.wait(1);
								countdown--;
							}

							if (this.inProgress && !this.IsEnding()) {
								info(`[${script.Name}] Countdown finished, stopping round`);
								task.defer(() => this.Stop());
							}
						}),
					);

					resolve(initialKillers);
				})
				.catch((e) => {
					warn(`[${script.Name}] startRound spawnPromise fail: ${e}`);
					this.cleanupRound();
					reject(e);
				});
		});
	}

	private cleanupRound() {
		if (!this.inProgress) return;

		info(`[${script.Name}] cleanupRound called`);
		this.inProgress = false;
		this.isEnding = true;
		this.trove.clean();
		this.KillerService.Clear();
	}

	private async initIntermissionCountdown(skipped: boolean): Promise<void> {
		return new Promise((resolve) => {
			task.spawn(() => {
				for (let i = RoundServiceClass.INTERMISSION_TIMEOUT; i >= 0; i--) {
					debug(`[${script.Name}] Round ${skipped ? "skipped" : "ended"} - next round in ${i}s`);
					print(`Round ${skipped ? "skipped" : "ended"} - Starting next round in ${i}s...`);
					task.wait(1);
				}
				return resolve();
			});
		});
	}

	private async endRound(preferredKiller: string, skipped: boolean): Promise<unknown> {
		return new Promise((resolve, reject) => {
			//  start command for example would skip the round, so it doesn't really count as a survival
			if (!skipped) {
				const survivors: string[] = [];
				const survivorPlayers: Player[] = [];
				for (const player of Players.GetPlayers()) {
					if (player.GetAttribute("Dead") === false) {
						survivors.push(player.Name);
						survivorPlayers.push(player);
						this.PlayerDataService.UpdatePlayerStat(player, "Survivals", 1);
					} else {
						// just reset back the attribute
						player.SetAttribute("Dead", false);
					}
				}

				if (survivors.size() === 0) {
					warn(`[${script.Name}] No survivors (preferredKiller=${preferredKiller})`);
					print("No survivors.");
				} else if (survivors.size() === 1) {
					info(`[${script.Name}] Last survivor: ${survivors[0]} (preferredKiller=${preferredKiller})`);
					print(`Survivor: ${survivors[0]}`);
				} else if (survivors.size() === Players.GetPlayers().size()) {
					info(`[${script.Name}] Everyone survived (preferredKiller=${preferredKiller})`);
					print("Everyone survived");
				} else {
					survivors.sort();
					info(`[${script.Name}] Survivors: ${survivors.join(", ")} (preferredKiller=${preferredKiller})`);
					print(`Survivors: ${survivors.join(", ")}.`);
				}

				for (const survivorPlayer of survivorPlayers) {
					this.PlayerDataService.UpdatePlayerStat(survivorPlayer, "Points", 25); // TODO: Maybe instead of giving a fixed ammount, give points based off the survival duration?
				}

				// little gap between the survivors and the actual intermission
				task.wait(RoundServiceClass.ANNOUNCEMENT_LIFETIME);
			}

			info(`[${script.Name}] Round ended (preferredKiller=${preferredKiller}, skipped=${skipped})`);
			this.RoundEnded.Fire(skipped);

			this.initIntermissionCountdown(skipped)
				.andThen(() => {
					this.isEnding = false;
					debug(`[${script.Name}] Intermission complete, beginning next round`);
					return this.Begin(preferredKiller);
				})
				.andThen(resolve, reject);
		});
	}

	/*
	--------------------------------------------------------------------
	--- Public API
	--------------------------------------------------------------------
	*/
	public async Begin(preferredKiller: string): Promise<Killer[]> {
		assert(!this.inProgress, "Round already in progress");
		assert(!this.isEnding, "Round is ending");
		assert(!this.OnIntermission(), "Round is in intermission");
		debug(`[${script.Name}] Begin called (preferredKiller=${preferredKiller})`);

		return this.startRound(preferredKiller);
	}

	public async Stop(preferredKiller?: string, skipped?: boolean): Promise<void> {
		if (this.isEnding) {
			warn(`[${script.Name}] Stop called while already ending`);
			return Promise.reject("Round already ending") as Promise<void>;
		}

		info(
			`[${script.Name}] Stop called (preferredKiller=${
				preferredKiller ?? RoundServiceClass.DEFAULT_PREFERRED_KILLER
			}, skipped=${skipped ?? false})`,
		);
		this.isEnding = true;

		this.cleanupRound();

		return this.endRound(
			preferredKiller ?? RoundServiceClass.DEFAULT_PREFERRED_KILLER,
			skipped ?? false,
		) as Promise<void>;
	}

	public OnIntermission(): boolean {
		return this.isEnding && !this.inProgress;
	}

	public IsEnding(): boolean {
		return this.isEnding;
	}
}
