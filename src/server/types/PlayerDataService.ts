/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";
import ProfileStore, { Profile } from "@rbxts/profile-store";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/
export type ValidStats = "Survivals" | "Points";

export type PlayerProfile = ProfileStore.Profile<PlayerData>;
export type ProfileStateChangedSignal = (player: Player, profile: PlayerProfile) => void;

export type PlayerData = {
	Survivals: number;
	Points: number;
	Version: number;
};
