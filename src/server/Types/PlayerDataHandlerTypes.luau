--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Maid = require(Packages:WaitForChild("maid"))
local Promise = require(Packages:WaitForChild("promise"))
local Signal = require(Packages:WaitForChild("signal"))

local ServerPackages = script.Parent.Parent.Packages
local ProfileStore = require(ServerPackages:WaitForChild("profilestore"))

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

export type PlayerDataHandler = {
	-- lifecycle
	Init: (self: PlayerDataHandler) -> (),
	Start: (self: PlayerDataHandler) -> (),

	-- public API
	GetPlayerData: (self: PlayerDataHandler, Player) -> TypedPromise<PlayerData>,
	SetPlayerStat: (self: PlayerDataHandler, Player, ValidStats, number) -> TypedPromise<boolean>,
	UpdatePlayerStat: (self: PlayerDataHandler, Player, ValidStats, number) -> TypedPromise<number>,
	ObserveSurvivals: (self: PlayerDataHandler, Player, (number) -> ()) -> TypedPromise<Signal.Connection>,
	ObservePoints: (self: PlayerDataHandler, Player, (number) -> ()) -> TypedPromise<Signal.Connection>,
	ClearPlayerData: (self: PlayerDataHandler, Player) -> TypedPromise<boolean>,

	-- events
	ProfileLoaded: ProfileStateChangedSignal,
	ProfileReleased: ProfileStateChangedSignal,

	-- private
	_init: boolean,
	_start: boolean,
	_store: ProfileStore.ProfileStore<PlayerData>,
	_profiles: { [Player]: PlayerProfile },
	_maids: { [Player]: Maid.Maid },
	_signals: { [Player]: { [string]: Signal.Signal<number> } },
	_loadingPromises: { [Player]: TypedPromise<PlayerProfile> },

	-- private methods
	_load: (self: PlayerDataHandler, Player) -> TypedPromise<PlayerProfile>,
	_release: (self: PlayerDataHandler, Player) -> TypedPromise<()>,
}

return (nil :: any) :: PlayerDataHandler
