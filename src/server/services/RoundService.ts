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
    ]
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
// Roblox services
import { Debris, Players, Workspace } from "@rbxts/services";

// Packages
import { Service, OnInit, OnStart } from "@flamework/core";
import { Trove } from "@rbxts/trove";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";

// Types
import { Killer } from "server/types/KillerServiceTypes";

// Networking

// Local utilities

// Services
import { KillerService } from "./KillerService";
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
	private readonly TOTAL_ROUND_DURATION = 120;
	private readonly ANNOUNCEMENT_LIFETIME = 3;
	private readonly INTERMISSION_TIMEOUT = 10;

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public onInit() {}

	public onStart() {
		// start the main loop.
		this.Begin("**").catch(warn);
	}

	/*
	--------------------------------------------------------------------
	--- Private Methods
	--------------------------------------------------------------------
	*/
	private async startRound(preferredKiller: string): Promise<Killer[]> {
		return new Promise((resolve, reject, onCancel) => {
			if (this.inProgress) return reject("Round already in progress");

			this.inProgress = true;
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
			} else if (preferredKiller === "**") {
				const candidates: string[] = this.KillerService.GetKillersName(false);
				killersToSpawn = candidates[math.random(1, candidates.size())]; // as of now, there are is only one killer spawn per round, next update to make it be more than one.
			} else {
				killersToSpawn = preferredKiller;
			}

			const spawnPromise =
				killersToSpawn !== "*"
					? this.KillerService.SpawnKillers([killersToSpawn], -1)
					: this.KillerService.SpawnAll(-1);

			print(preferredKiller, killersToSpawn);
			spawnPromise
				.andThen((initialKillers) => {
					if (cancelled) return;

					if (initialKillers.size() === 0) {
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
									this.Stop().catch(warn);
								} else {
									// TODO: Since this is deprecated, I'll have to make them into a gui notification
									print(`${killer} has been killed.`);
									// const announcement = new Instance("Message") as TextLabel;
									// announcement.Parent = Workspace;
									// announcement.Text = `${killer} has been killed.`;
									// Debris.AddItem(announcement, this.ANNOUNCEMENT_LIFETIME);
								}
							});
						}),
					);

					this.trove.add(
						task.spawn(() => {
							let countdown = this.TOTAL_ROUND_DURATION;
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
									print("No killers.");
									// this.countdownHint.Text = "No killers.";
									task.wait(3);
									break;
								} else if (killerCount === 1) {
									print(`${cachedNames[0]} leaves in ${countdown}s`);
									// this.countdownHint.Text = `${cachedNames[0]} leaves in ${countdown}s`;
								} else {
									if (killerCount > 5) {
										print(`${killerCount} killers will leave in ${countdown}s`);
										// this.countdownHint.Text = `${killerCount} killers will leave in ${countdown}s`;
									} else {
										print(`${cachedNames.join(", ")} will leave in ${countdown}s.`);
										// this.countdownHint.Text = `${cachedNames.join(", ")} will leave in ${countdown}s.`;
									}
								}

								task.wait(1);
								countdown--;
							}

							if (this.inProgress && !this.isEnding) task.defer(() => this.Stop().catch(warn));
						}),
					);

					resolve(initialKillers);
				})
				.catch((e) => {
					this.cleanupRound();
					reject(e);
				});
		});
	}

	private cleanupRound() {
		if (!this.inProgress) return;

		this.inProgress = false;
		this.isEnding = true;
		this.trove.clean();
		this.KillerService.Clear();
	}

	private async initIntermissionCountdown(skipped: boolean): Promise<void> {
		return new Promise((resolve) => {
			task.spawn(() => {
				for (let i = this.INTERMISSION_TIMEOUT; i >= 0; i--) {
					print(`Round ${skipped ? "skipped" : "ended"} - Starting next round in ${i}s...`);
					// this.countdownHint.Text = `Round ${skipped ? "skipped" : "ended"} - Starting next round in ${i}s...`;
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

				// TODO: Since this is deprecated, I'll have to make them into a gui notification
				// const announcement = new Instance("Message") as TextLabel;
				// announcement.Parent = Workspace;

				if (survivors.size() === 0) print("No survivors.");
				//announcement.Text = "No survivors.";
				else if (survivors.size() === 1) print(`Survivor: ${survivors[0]}`);
				//announcement.Text = `Survivor: ${survivors[0]}.`;
				else if (survivors.size() === Players.GetPlayers().size()) print("Everyone survived");
				//announcement.Text = "Everyone survived.";
				else {
					survivors.sort();
					print(`Survivors: ${survivors.join(", ")}.`);
					// announcement.Text = `Survivors: ${survivors.join(", ")}.`;
				}

				// Debris.AddItem(announcement, this.ANNOUNCEMENT_LIFETIME);

				for (const survivorPlayer of survivorPlayers) {
					this.PlayerDataService.UpdatePlayerStat(survivorPlayer, "Points", 25).catch(warn); // TODO: Maybe instead of giving a fixed ammount, give points based off the survival duration?
				}

				// little gap between the survivors and the actual intermission
				task.wait(this.ANNOUNCEMENT_LIFETIME);
			}

			// maybe its name would be better if it was smth like "OnIntermission"
			this.RoundEnded.Fire(skipped || false);

			this.initIntermissionCountdown(skipped)
				.andThen(() => {
					this.isEnding = false;
					// TODO: probably add duos or just multiple killers to survive?
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
		assert(!this.isEnding, "Round is ending");
		assert(!this.OnIntermission(), "Cannot start round during intermission");

		if (this.inProgress) {
			return this.Stop(preferredKiller, true).andThen(() => this.startRound(preferredKiller));
		}

		return this.startRound(preferredKiller);
	}

	public OnIntermission(): boolean {
		return this.isEnding && !this.inProgress;
	}

	public async Stop(preferredKiller?: string, skipped?: boolean): Promise<void> {
		assert(!this.isEnding, "Round already ending");
		this.isEnding = true;

		this.cleanupRound();

		return this.endRound(preferredKiller ?? "**", skipped || false) as Promise<void>;
	}

	public GetIntermissionTimeout(): number {
		return this.INTERMISSION_TIMEOUT;
	}

	public IsEnding(): boolean {
		return this.isEnding;
	}
}
