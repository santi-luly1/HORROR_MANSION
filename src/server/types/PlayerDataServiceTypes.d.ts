/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";
import ProfileStore from "@rbxts/profile-store";

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

export default interface PlayerDataServiceMembers {
	// public API
	GetPlayerData: (this: PlayerDataServiceMembers, player: Player) => Promise<PlayerData>;
	SetPlayerStat: (
		this: PlayerDataServiceMembers,
		player: Player,
		stat: ValidStats,
		value: number,
	) => Promise<boolean>;
	UpdatePlayerStat: (
		this: PlayerDataServiceMembers,
		player: Player,
		stat: ValidStats,
		value: number,
	) => Promise<number>;
	ObserveSurvivals: (
		this: PlayerDataServiceMembers,
		player: Player,
		callback: (newValue: number) => void,
	) => Promise<RBXScriptConnection>;
	ObservePoints: (
		this: PlayerDataServiceMembers,
		player: Player,
		callback: (newValue: number) => void,
	) => Promise<RBXScriptConnection>;
	ClearPlayerData: (this: PlayerDataServiceMembers, player: Player) => Promise<boolean | unknown>;

	// events
	ProfileLoaded: ProfileStateChangedSignal;
	ProfileReleased: ProfileStateChangedSignal;
}
