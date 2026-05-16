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
import { Trove } from "@rbxts/trove";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";

// Types
import * as Types from "server/types/RoundServiceTypes";
import { KillerServiceTypes, Killer } from "server/types/KillerServiceTypes";
import { PlayerDataServiceTypes } from "server/types/PlayerDataServiceTypes";

// Networking

// Local utilities

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/
class RoundServiceClass implements Types.RoundServiceTypes {
	/*
		state
	*/
	private init = false;
	private start = false;
	private inProgress = false;
	private isEnding = false;

	/*
		runtime fields
	*/
	public RoundStarted = new Signal<(preferredKiller: string) => void>();
	public RoundEnded = new Signal<(skipped: boolean) => void>();
	private trove?: Trove;

	/*
		dependencies
	*/
	private KillerService!: KillerServiceTypes;
	private PlayerDataService!: PlayerDataServiceTypes;
	public static Dependencies = ["KillerService", "PlayerDataService"];

	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/
	// @ts-expect-error: "Hint" is not a valid member, probably bc it is deprecated.
	private countdownHint = new Instance("Hint");
	private readonly TOTAL_ROUND_DURATION = 120;
	private readonly ANNOUNCEMENT_LIFETIME = 3;
	private readonly INTERMISSION_TIMEOUT = 10;

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public Init(registry: Map<string, unknown>) {
		assert(!this.init, `[${script.Name}] - Module already initialized.`);
		this.init = true;

		this.KillerService = registry.get("KillerService") as KillerServiceTypes;
		this.PlayerDataService = registry.get("PlayerDataService") as PlayerDataServiceTypes;

		this.countdownHint.Parent = Workspace;
	}

	public Start() {
		assert(this.init, `[${script.Name}] - Module not initialized.`);
		assert(!this.start, `[${script.Name}] - Module already started.`);
		this.start = true;

		this.Begin("**"); // start the main loop.
	}

	/*
	--------------------------------------------------------------------
	--- Private Methods
	--------------------------------------------------------------------
	*/
	private startRound(preferredKiller: string): Promise<Killer[]> {
		return new Promise((resolve, reject, onCancel) => {
			if (this.inProgress) return reject("Round already in progress");

			this.inProgress = true;
			this.RoundStarted.Fire(preferredKiller);

			const trove = new Trove();
			this.trove = trove;

			let cancelled = false;
			if (
				onCancel(() => {
					cancelled = true;
					this.cleanupRound(trove);
				})
			)
				return;

			let killersToSpawn: string[] | undefined;

			if (preferredKiller === "*") {
				killersToSpawn = undefined; // SpawnAll handles this
			} else if (preferredKiller === "**") {
				const all: string[] = [];
				for (const name of this.KillerService.GetKillersName()) {
					if (this.KillerService.IsValidName(name)) all.push(name);
				}
				killersToSpawn = [all[math.random(1, all.size())]];
			} else {
				killersToSpawn = [preferredKiller];
			}

			const spawnPromise = killersToSpawn
				? this.KillerService.SpawnKillers(killersToSpawn, -1)
				: this.KillerService.SpawnAll(-1);

			spawnPromise
				.andThen((initialKillers) => {
					if (cancelled) return;

					if (initialKillers.size() === 0) {
						this.cleanupRound(trove);
						return reject("No killers spawned");
					}

					trove.add(
						this.KillerService.KillerCleared.Connect((killer) => {
							if (this.isEnding || !this.inProgress) return;

							task.defer(() => {
								const remaining = this.KillerService.GetCurrentKillers();
								if (remaining.size() < 1 && !this.isEnding) {
									this.Stop().catch(warn);
								} else {
									// @ts-expect-error: "Message" is not a valid member, probably bc it is deprecated.
									const announcement = new Instance("Message");
									announcement.Parent = Workspace;
									announcement.Text = `${killer} has been killed.`;
									Debris.AddItem(announcement, this.ANNOUNCEMENT_LIFETIME);
								}
							});
						}),
					);

					trove.add(
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

							trove.add(this.KillerService.KillerSpawned.Connect(() => (cachedCount = -1)));

							while (countdown >= 0 && this.inProgress && !this.isEnding) {
								updateCache();

								if (killerCount === 0) {
									this.countdownHint.Text = "No killers.";
									task.wait(3);
									break;
								} else if (killerCount === 1) {
									this.countdownHint.Text = `${cachedNames[0]} leaves in ${countdown}s`;
								} else {
									if (killerCount > 5) {
										this.countdownHint.Text = `${killerCount} killers will leave in ${countdown}s`;
									} else {
										const lastIdx = cachedNames.size();
										this.countdownHint.Text = `${cachedNames
											.slice(0, lastIdx - 1)
											.join(", ")} and ${cachedNames[lastIdx]} will leave in ${countdown}s.`;
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
					this.cleanupRound(trove);
					reject(e);
				});
		});
	}

	private cleanupRound(trove: Trove) {
		if (!this.inProgress) return;

		this.inProgress = false;
		this.isEnding = true;
		trove.destroy();
		this.KillerService.Clear();
		this.trove = undefined;
	}

	private initIntermissionCountdown(skipped: boolean): Promise<void> {
		return new Promise((resolve) => {
			task.spawn(() => {
				for (let i = this.INTERMISSION_TIMEOUT; i >= 0; i--) {
					this.countdownHint.Text = `Round ${
						skipped ? "skipped" : "ended"
					} - Starting next round in ${i}s...`;
					task.wait(1);
				}
				resolve();
			});
		});
	}

	private endRound(preferredKiller: string, skipped: boolean): Promise<void> {
		return new Promise((resolve, reject) => {
			if (!skipped) {
				const survivors: string[] = [];
				const survivorPlayers: Player[] = [];
				for (const player of Players.GetPlayers()) {
					if (player.GetAttribute("Dead") === false) {
						survivors.push(player.Name);
						survivorPlayers.push(player);
						this.PlayerDataService.UpdatePlayerStat(player, "Survivals", 1);
					} else {
						player.SetAttribute("Dead", false);
					}
				}

				// @ts-expect-error: "Message" is not a valid member, probably bc it is deprecated.
				const announcement = new Instance("Message");
				announcement.Parent = Workspace;

				if (survivors.size() === 0) announcement.Text = "No survivors.";
				else if (survivors.size() === 1) announcement.Text = `Survivor: ${survivors[0]}.`;
				else {
					survivors.sort();
					const lastIdx = survivors.size();
					announcement.Text = `Survivors: ${survivors.slice(0, lastIdx - 1).join(", ")} and ${
						survivors[lastIdx]
					}.`;
				}

				Debris.AddItem(announcement, this.ANNOUNCEMENT_LIFETIME);

				for (const survivorPlayer of survivorPlayers) {
					this.PlayerDataService.UpdatePlayerStat(survivorPlayer, "Points", 25).catch(warn);
				}

				task.wait(this.ANNOUNCEMENT_LIFETIME);
			}

			this.RoundEnded.Fire(skipped || false);

			this.initIntermissionCountdown(skipped)
				.andThen(() => {
					this.isEnding = false;
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
	public Begin(preferredKiller: string): Promise<Killer[] | unknown> {
		if (this.isEnding) return Promise.reject("Round is ending");
		if (this.OnIntermission()) return Promise.reject("Cannot start round during intermission");

		if (this.inProgress) {
			return this.Stop(preferredKiller, true).andThen(() => this.startRound(preferredKiller));
		}

		return this.startRound(preferredKiller);
	}

	public OnIntermission(): boolean {
		return this.isEnding && !this.inProgress;
	}

	public Stop(preferredKiller?: string, skipped?: boolean): Promise<void> {
		if (this.isEnding) return Promise.reject("Round already ending");
		this.isEnding = true;

		if (this.trove) this.cleanupRound(this.trove);

		return this.endRound(preferredKiller ?? "**", skipped || false);
	}

	public GetIntermissionTimeout(): number {
		return this.INTERMISSION_TIMEOUT;
	}

	public IsEnding(): boolean {
		return this.isEnding;
	}
}

/*
--------------------------------------------------------------------
--- Export
--------------------------------------------------------------------
*/
const RoundService = new RoundServiceClass();
export = RoundService;
