/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";
import ProfileStore from "@rbxts/profile-store";
import _SERVICE from "./_SERVICE";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/
export type ValidStats = "Survivals" | "Points";

export type PlayerProfile = ProfileStore.Profile<PlayerData>;
export type ProfileStateChangedSignal = Signal<(player: Player, profile: PlayerProfile) => void>;

export type PlayerData = {
	Survivals: number;
	Points: number;
	Version: number;
};

export interface PlayerDataServiceMembers {
	// public API
	GetPlayerData: (this: PlayerDataServiceTypes, player: Player) => Promise<PlayerData>;
	SetPlayerStat: (this: PlayerDataServiceTypes, player: Player, stat: ValidStats, value: number) => Promise<boolean>;
	UpdatePlayerStat: (
		this: PlayerDataServiceTypes,
		player: Player,
		stat: ValidStats,
		value: number,
	) => Promise<number>;
	ObserveSurvivals: (
		this: PlayerDataServiceTypes,
		player: Player,
		callback: (newValue: number) => void,
	) => Promise<RBXScriptConnection>;
	ObservePoints: (
		this: PlayerDataServiceTypes,
		player: Player,
		callback: (newValue: number) => void,
	) => Promise<RBXScriptConnection>;
	ClearPlayerData: (this: PlayerDataServiceTypes, player: Player) => Promise<boolean | unknown>;

	// events
	ProfileLoaded: ProfileStateChangedSignal;
	ProfileReleased: ProfileStateChangedSignal;
}

export type PlayerDataServiceTypes = _SERVICE.Service<PlayerDataServiceMembers>;

declare const _default: PlayerDataServiceTypes;
export default _default;
