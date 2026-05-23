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
import { Trove } from "@rbxts/trove";
import ProfileStore from "@rbxts/profile-store";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";
import { t } from "@rbxts/t";

// Types
import * as Types from "server/types/PlayerDataServiceTypes";

// Networking
import Networking from "shared/networking/PlayerDataNetwork";

// Local utilities

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/
class PlayerDataService implements Types.PlayerDataServiceTypes {
	/*
		state
	*/
	private init = false;
	private start = false;

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

	public ProfileLoaded: Types.ProfileStateChangedSignal = new Signal();
	public ProfileReleased: Types.ProfileStateChangedSignal = new Signal();

	private playerCheck = t.instanceOf("Player");
	private updateCheck = t.strictArray(t.instanceOf("Player"), t.literal("Survivals", "Points"), t.number);

	private declare store: ProfileStore.Store<Types.PlayerData>;

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public Init() {
		assert(!this.init, `[${script.Name}] already initialized`);
		this.init = true;

		this.store = ProfileStore.New(this.DATASTORE_KEY, this.TEMPLATE);
	}

	public Start() {
		assert(this.init, `[${script.Name}] - Module not initialized.`);
		assert(!this.start, `[${script.Name}] - Module already started.`);
		this.start = true;

		Players.PlayerRemoving.Connect((player) => {
			this.release(player).catch(warn);
		});

		const createProfileForPlayer = (player: Player) => {
			this.load(player)
				.andThen(() => print(`[${script.Name}] loaded ${player.Name}'s profile`))
				.catch(warn);
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
	private load(player: Player): Promise<Types.PlayerProfile> {
		if (this.loadingPromises.has(player)) {
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
				task.wait(this.YIELD_PER_RETRY * 2 ** (attempt - 1));
			}

			if (!profile)
				return reject(
					`[${script.Name}] could not load profile for ${player.Name} after ${this.MAX_RETRIES} tries`,
				);
			if (!profile.Data || !typeIs(profile.Data, "table")) {
				profile.EndSession();
				return reject(`[${script.Name}] invalid profile data for ${player.Name}`);
			}

			profile.AddUserId(player.UserId);
			profile.Reconcile();

			if (profile.Data.Version !== this.PROFILE_VERSION) {
				// we don't have proper migration, whatever.
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
			resolve(profile);
		});

		this.loadingPromises.set(player, promise);
		promise.finally(() => this.loadingPromises.delete(player));

		return promise;
	}

	private release(player: Player): Promise<void> {
		return new Promise((resolve) => {
			assert(this.playerCheck(player));

			const loading = this.loadingPromises.get(player);
			if (loading) loading.await();

			const trove = this.troves.get(player);
			const sig = this.signals.get(player);
			if (trove) trove.destroy();
			this.troves.delete(player);
			this.signals.delete(player);

			const profile = this.profiles.get(player);
			if (profile) {
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
	public GetPlayerData(player: Player): Promise<Types.PlayerData> {
		return new Promise((resolve, reject) => {
			assert(this.playerCheck(player));

			const profile = this.profiles.get(player);
			if (!profile) return reject(`[${script.Name}] profile not loaded for ${player.Name}`);

			resolve({ ...profile.Data });
		});
	}

	public SetPlayerStat(player: Player, statName: Types.ValidStats, value: number): Promise<boolean> {
		return new Promise((resolve, reject) => {
			assert(this.updateCheck([player, statName, value]));

			const profile = this.profiles.get(player);
			const sig = this.signals.get(player);
			if (!profile) return reject(`[${script.Name}] profile not loaded for ${player.Name}`);
			if (!typeIs(sig, "table")) return reject(`[${script.Name}] signals not initialized for ${player.Name}`);

			if (profile.Data[statName] === value) return resolve(true);

			profile.Data[statName] = value;
			sig[this.SIGNAL_NAMES[statName]].Fire(value);

			resolve(true);
		});
	}

	public UpdatePlayerStat(player: Player, statName: Types.ValidStats, delta: number): Promise<number> {
		return new Promise((resolve, reject) => {
			assert(this.updateCheck([player, statName, delta]));

			const profile = this.profiles.get(player);
			const sig = this.signals.get(player);
			if (!profile) return reject(`[${script.Name}] profile not loaded for ${player.Name}`);
			if (!typeIs(sig, "table")) return reject(`[${script.Name}] signals not initialized for ${player.Name}`);

			const newValue = profile.Data[statName] + delta;
			if (profile.Data[statName] === newValue) return resolve(newValue);

			profile.Data[statName] = newValue;
			sig[this.SIGNAL_NAMES[statName]].Fire(newValue);

			resolve(newValue);
		});
	}

	public ObserveSurvivals(player: Player, callback: (newValue: number) => void): Promise<RBXScriptConnection> {
		return new Promise((resolve, reject) => {
			assert(this.playerCheck(player));

			const sig = this.signals.get(player);
			if (!typeIs(sig, "table")) return reject(`[${script.Name}] signals not initialized for ${player.Name}`);

			resolve(sig.SurvivalsChanged.Connect(callback));
		});
	}

	public ObservePoints(player: Player, callback: (newValue: number) => void): Promise<RBXScriptConnection> {
		return new Promise((resolve, reject) => {
			assert(this.playerCheck(player));

			const sig = this.signals.get(player);
			if (!typeIs(sig, "table")) return reject(`[${script.Name}] signals not initialized for ${player.Name}`);

			resolve(sig.PointsChanged.Connect(callback));
		});
	}

	/*
	--------------------------------------------------------------------
	--- Studio-only
	--------------------------------------------------------------------
	*/
	public ClearPlayerData(player: Player): Promise<boolean | unknown> {
		if (!RunService.IsStudio()) {
			return Promise.reject(`[${script.Name}] ClearPlayerData can only be used in Studio`);
		}

		assert(this.playerCheck(player));

		return Promise.all([
			this.SetPlayerStat(player, "Survivals", 0),
			this.SetPlayerStat(player, "Points", 0),
		]).andThen(() => true);
	}
}

/*
--------------------------------------------------------------------
--- Export
--------------------------------------------------------------------
*/
const PlayerDataServiceInstance = new PlayerDataService();
export = PlayerDataServiceInstance;
