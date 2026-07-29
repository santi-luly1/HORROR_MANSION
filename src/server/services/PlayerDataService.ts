/*
[=[
	@class PlayerDataService
    @author santi-luly1
	@description Main API for player data

	CHANGELOG:
		25/12/25 --> Added t module support & methods now returns promises.
		25/12/26 --> Fixed some t validations, new print formatting, fixed C stack overflow error from signal, signals
					fire remotes for the client and now using Promises.try on public APIs.
		25/12/31 --> Added retry/back-off, consistent error handling, fixed isPlayer type-check, added profile-versioning, etc.
		26/01/09 --> Added Promise typechecking.
		26/01/11 --> Entire module is now typechecked.
		26/01/30 --> Removed Promise.try for a better Promise chain.
		26/02/16 --> Fixed race conditions.
		26/03/13 --> Added signal checks to avoid stat updates during player removal (AI).
        26/05/15 --> Parsed into roblox-ts.
		26/07/16 --> Implemented logger.
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
// Roblox services
import { Players, RunService } from "@rbxts/services";

// Packages
import { Service, OnInit, OnStart } from "@flamework/core";
import { Trove } from "@rbxts/trove";
import { debug, info, warn } from "@rbxts/logger";
import ProfileStore from "@rbxts/profile-store";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";
import { t } from "@rbxts/t";

// Types
import * as Types from "server/types/PlayerDataService";

// Networking
import Networking from "shared/networking/PlayerDataNetwork";

// Local utilities

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export default class PlayerDataService implements OnInit, OnStart {
	/*
		runtime fields
	*/
	private profiles = new Map<Player, Types.PlayerProfile>();
	private troves = new Map<Player, Trove>();
	private signals = new Map<Player, Record<string, Signal<(newValue: number) => void>>>();
	private loadingPromises = new Map<Player, Promise<Types.PlayerProfile>>();

	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/
	public readonly ProfileLoaded = new Signal<Types.ProfileStateChangedSignal, false>();
	public readonly ProfileReleased = new Signal<Types.ProfileStateChangedSignal, false>();
	private readonly DATASTORE_KEY = RunService.IsStudio() ? "Studio" : "Live";
	private readonly MAX_RETRIES = 5;
	private readonly YIELD_PER_RETRY = 2; // seconds
	private readonly PROFILE_VERSION = 1; // bump when template changes
	private readonly SIGNAL_NAMES: Record<Types.ValidStats, string> = {
		Survivals: "SurvivalsChanged",
		Points: "PointsChanged",
	};

	private readonly TEMPLATE: Types.PlayerData = {
		Survivals: 0,
		Points: 0,
		Version: this.PROFILE_VERSION,
	};

	private playerCheck = t.instanceOf("Player");
	private updateCheck = t.strictArray(t.instanceOf("Player"), t.literal("Survivals", "Points"), t.number);

	private declare store: ProfileStore.Store<Types.PlayerData>;

	/*
	--------------------------------------------------------------------
	--- Constructor
	--------------------------------------------------------------------
	*/
	public constructor() {}

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public onInit() {
		this.store = ProfileStore.New(this.DATASTORE_KEY, this.TEMPLATE);

		Players.PlayerRemoving.Connect((player) => {
			debug(`[${script.Name}] PlayerRemoving: ${player.Name}`);
			this.release(player);
		});

		info(`[${script.Name}] Initialized (datastore: ${this.DATASTORE_KEY})`);
	}

	public onStart() {
		const createProfileForPlayer = (player: Player) => {
			debug(`[${script.Name}] PlayerAdded: ${player.Name} -> loading profile`);
			this.load(player)
				.andThen(() => info(`[${script.Name}] loaded ${player.Name}'s profile`))
				.catch((e) => warn(`[${script.Name}] failed loading profile for ${player.Name}: ${e}`));
		};

		Players.PlayerAdded.Connect(createProfileForPlayer);

		for (const player of Players.GetPlayers()) {
			task.spawn(() => createProfileForPlayer(player));
		}
	}

	/*
	--------------------------------------------------------------------
	--- Private Methods
	--------------------------------------------------------------------
	*/
	private async load(player: Player): Promise<Types.PlayerProfile> {
		if (this.loadingPromises.has(player)) {
			debug(`[${script.Name}] load() dedup hit for ${player.Name}`);
			return this.loadingPromises.get(player)!;
		}

		const promise = new Promise<Types.PlayerProfile>((resolve, reject) => {
			assert(this.playerCheck(player));

			let profile: Types.PlayerProfile | undefined;
			for (let attempt = 1; attempt <= this.MAX_RETRIES; attempt++) {
				profile = this.store.StartSessionAsync(`P_${player.UserId}`, {
					Cancel: () => player.Parent !== Players,
				});
				if (profile) break;
				debug(`[${script.Name}] load retry ${attempt}/${this.MAX_RETRIES} for ${player.Name} (not ready)`);
				task.wait(this.YIELD_PER_RETRY * 2 ** (attempt - 1));
			}

			if (!profile) {
				warn(`[${script.Name}] could not load profile for ${player.Name} after ${this.MAX_RETRIES} tries`);
				return reject(
					`[${script.Name}] could not load profile for ${player.Name} after ${this.MAX_RETRIES} tries`,
				);
			}

			if (!profile.Data || !typeIs(profile.Data, "table")) {
				warn(`[${script.Name}] invalid profile data for ${player.Name}`);
				profile.EndSession();
				return reject(`[${script.Name}] invalid profile data for ${player.Name}`);
			}

			profile.AddUserId(player.UserId);
			profile.Reconcile();

			if (profile.Data.Version !== this.PROFILE_VERSION) {
				// we don't have proper migration, whatever.
				info(
					`[${script.Name}] profile version mismatch for ${player.Name}: was ${profile.Data.Version}, now ${this.PROFILE_VERSION}`,
				);
				profile.Data.Version = this.PROFILE_VERSION;
			}

			this.profiles.set(player, profile);

			const trove = new Trove();
			this.troves.set(player, trove);

			const plrSignals = {
				SurvivalsChanged: new Signal<(newValue: number) => void>(),
				PointsChanged: new Signal<(newValue: number) => void>(),
			};
			this.signals.set(player, plrSignals);
			trove.add(plrSignals.PointsChanged);
			trove.add(plrSignals.PointsChanged);

			// leaderstats
			const ls = new Instance("Folder");
			ls.Name = "leaderstats";
			ls.Parent = player;
			trove.add(ls);

			const survVal = new Instance("IntValue");
			survVal.Name = "Survivals";
			survVal.Value = profile.Data.Survivals;
			survVal.Parent = ls;
			trove.add(survVal);

			const pointVal = new Instance("IntValue");
			pointVal.Name = "Points";
			pointVal.Value = profile.Data.Points;
			pointVal.Parent = ls;
			trove.add(pointVal);

			this.ObserveSurvivals(player, (newVal) => {
				survVal.Value = newVal;
				Networking.Server.Get("SurvivalsChanged").SendToPlayer(player, newVal);
			})
				.andThen((conn) => trove.add(conn))
				.catch((e) =>
					warn(`[${script.Name}] Failed to observe ${player.Name}'s survivals, expect visual bugs: ${e}`),
				);

			this.ObservePoints(player, (newVal) => {
				pointVal.Value = newVal;
				Networking.Server.Get("PointsChanged").SendToPlayer(player, newVal);
			})
				.andThen((conn) => trove.add(conn))
				.catch((e) =>
					warn(`[${script.Name}] Failed to observe ${player.Name}'s points, expect visual bugs: ${e}`),
				);

			this.ProfileLoaded.Fire(player, profile);

			debug(`[${script.Name}] load() resolved for ${player.Name}`);
			resolve(profile);
		});

		this.loadingPromises.set(player, promise);
		promise.finally(() => {
			this.loadingPromises.delete(player);
			debug(`[${script.Name}] load() finalized for ${player.Name}`);
		});

		return promise;
	}

	private async release(player: Player): Promise<void> {
		return new Promise((resolve) => {
			assert(this.playerCheck(player));
			debug(`[${script.Name}] release() called for ${player.Name}`);

			const loading = this.loadingPromises.get(player);
			if (loading) loading.await();

			const trove = this.troves.get(player);
			if (trove) trove.destroy();
			this.troves.delete(player);
			this.signals.delete(player);

			const profile = this.profiles.get(player);
			if (profile) {
				info(`[${script.Name}] releasing profile for ${player.Name}`);
				profile.EndSession();
				this.ProfileReleased.Fire(player, profile);
			}
			this.profiles.delete(player);

			return resolve();
		});
	}

	/*
	--------------------------------------------------------------------
	--- Public API
	--------------------------------------------------------------------
	*/
	public async GetPlayerData(player: Player): Promise<Types.PlayerData> {
		return new Promise((resolve, reject) => {
			assert(this.playerCheck(player));

			const profile = this.profiles.get(player);
			if (!profile) {
				warn(`[${script.Name}] GetPlayerData: profile not loaded for ${player.Name}`);
				return reject(`[${script.Name}] profile not loaded for ${player.Name}`);
			}

			debug(`[${script.Name}] GetPlayerData ok for ${player.Name}`);
			resolve({ ...profile.Data });
		});
	}

	public async SetPlayerStat(player: Player, statName: Types.ValidStats, value: number): Promise<boolean> {
		return new Promise((resolve, reject) => {
			assert(this.updateCheck([player, statName, value]));

			const profile = this.profiles.get(player);
			const sig = this.signals.get(player);
			if (!profile) {
				warn(`[${script.Name}] SetPlayerStat: profile not loaded for ${player.Name}`);
				return reject(`[${script.Name}] profile not loaded for ${player.Name}`);
			}
			if (!typeIs(sig, "table")) {
				warn(`[${script.Name}] SetPlayerStat: signals not initialized for ${player.Name}`);
				return reject(`[${script.Name}] signals not initialized for ${player.Name}`);
			}

			if (profile.Data[statName] === value) {
				debug(`[${script.Name}] SetPlayerStat same value for ${player.Name}.${statName}`);
				return resolve(true);
			}

			debug(`[${script.Name}] SetPlayerStat ${player.Name}.${statName}=${value}`);
			profile.Data[statName] = value;
			sig[this.SIGNAL_NAMES[statName]].Fire(value);

			resolve(true);
		});
	}

	public async UpdatePlayerStat(player: Player, statName: Types.ValidStats, delta: number): Promise<number> {
		return new Promise((resolve, reject) => {
			assert(this.updateCheck([player, statName, delta]));

			const profile = this.profiles.get(player);
			const sig = this.signals.get(player);
			if (!profile) {
				warn(`[${script.Name}] UpdatePlayerStat: profile not loaded for ${player.Name}`);
				return reject(`[${script.Name}] profile not loaded for ${player.Name}`);
			}
			if (!typeIs(sig, "table")) {
				warn(`[${script.Name}] UpdatePlayerStat: signals not initialized for ${player.Name}`);
				return reject(`[${script.Name}] signals not initialized for ${player.Name}`);
			}

			const newValue = profile.Data[statName] + delta;
			if (profile.Data[statName] === newValue) {
				debug(`[${script.Name}] UpdatePlayerStat same value for ${player.Name}.${statName}`);
				return resolve(newValue);
			}

			debug(`[${script.Name}] UpdatePlayerStat ${player.Name}.${statName} + (${delta}) => ${newValue}`);
			profile.Data[statName] = newValue;
			sig[this.SIGNAL_NAMES[statName]].Fire(newValue);

			resolve(newValue);
		});
	}

	public async ObserveSurvivals(player: Player, callback: (newValue: number) => void): Promise<RBXScriptConnection> {
		return new Promise((resolve, reject) => {
			assert(this.playerCheck(player));

			const sig = this.signals.get(player);
			if (!typeIs(sig, "table")) {
				warn(`[${script.Name}] ObserveSurvivals: signals not initialized for ${player.Name}`);
				return reject(`[${script.Name}] signals not initialized for ${player.Name}`);
			}

			debug(`[${script.Name}] ObserveSurvivals connected for ${player.Name}`);
			resolve(sig.SurvivalsChanged.Connect(callback));
		});
	}

	public async ObservePoints(player: Player, callback: (newValue: number) => void): Promise<RBXScriptConnection> {
		return new Promise((resolve, reject) => {
			assert(this.playerCheck(player));

			const sig = this.signals.get(player);
			if (!typeIs(sig, "table")) {
				warn(`[${script.Name}] ObservePoints: signals not initialized for ${player.Name}`);
				return reject(`[${script.Name}] signals not initialized for ${player.Name}`);
			}

			debug(`[${script.Name}] ObservePoints connected for ${player.Name}`);
			resolve(sig.PointsChanged.Connect(callback));
		});
	}

	/*
	--------------------------------------------------------------------
	--- Studio-only
	--------------------------------------------------------------------
	*/
	public async ClearPlayerData(player: Player): Promise<boolean | unknown> {
		if (!RunService.IsStudio()) {
			warn(`[${script.Name}] ClearPlayerData called outside Studio`);
			return Promise.reject(`[${script.Name}] ClearPlayerData can only be used in Studio`);
		}

		assert(this.playerCheck(player));
		info(`[${script.Name}] ClearPlayerData: resetting stats for ${player.Name}`);

		return Promise.all([
			this.SetPlayerStat(player, "Survivals", 0),
			this.SetPlayerStat(player, "Points", 0),
		]).andThen(() => true);
	}
}
