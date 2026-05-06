--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Maid = require("@game/ReplicatedStorage/Packages/maid")
local Promise = require("@game/ReplicatedStorage/Packages/promise")
local Signal = require("@game/ReplicatedStorage/Packages/signal")
local _SERVICE = require("@game/ServerScriptService/Server/Types/_SERVICE")

local ProfileStore = require("@game/ServerStorage/ServerPackages/profilestore")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>
export type ValidStats = "Survivals" | "Points"

export type PlayerData = {
	Survivals: number,
	Points: number,
	Version: number,
}

export type PlayerProfile = ProfileStore.Profile<PlayerData>
export type ProfileStateChangedSignal = Signal.Signal<Player, PlayerProfile>

export type PlayerDataService = _SERVICE.SERVICE<PlayerDataService> & {
	-- public API
	GetPlayerData: (self: PlayerDataService, Player) -> TypedPromise<PlayerData>,
	SetPlayerStat: (self: PlayerDataService, Player, ValidStats, number) -> TypedPromise<boolean>,
	UpdatePlayerStat: (self: PlayerDataService, Player, ValidStats, number) -> TypedPromise<number>,
	ObserveSurvivals: (self: PlayerDataService, Player, (newValue: number) -> ()) -> TypedPromise<Signal.Connection>,
	ObservePoints: (self: PlayerDataService, Player, (newValue: number) -> ()) -> TypedPromise<Signal.Connection>,
	ClearPlayerData: (self: PlayerDataService, Player) -> TypedPromise<boolean>,

	-- events
	ProfileLoaded: ProfileStateChangedSignal,
	ProfileReleased: ProfileStateChangedSignal,

	-- private
	_store: ProfileStore.ProfileStore<PlayerData>,
	_profiles: { [Player]: PlayerProfile },
	_maids: { [Player]: Maid.Maid },
	_signals: { [Player]: { [string]: Signal.Signal<number> } },
	_loadingPromises: { [Player]: TypedPromise<PlayerProfile> },

	-- private methods
	_load: (self: PlayerDataService, Player) -> TypedPromise<PlayerProfile>,
	_release: (self: PlayerDataService, Player) -> TypedPromise<()>,
}

return (nil :: any) :: PlayerDataService
