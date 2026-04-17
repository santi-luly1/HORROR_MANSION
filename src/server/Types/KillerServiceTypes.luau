--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Maid = require(Packages.maid)
local Promise = require(Packages:WaitForChild("promise"))
local Signal = require(Packages:WaitForChild("signal"))
local _SERVICE = require(script.Parent._SERVICE)

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

export type KillerService = _SERVICE.SERVICE<KillerService> & {
	-- public API
	SpawnKillers: (self: KillerService, names: { string }, spawnIndex: number) -> TypedPromise<{ Model }>,
	SpawnAll: (self: KillerService, spawnIndex: number) -> TypedPromise<{ Model }>,
	SpawnKiller: (self: KillerService, name: string, spawnIndex: number) -> TypedPromise<Model, number>,
	GetCurrentKillers: (self: KillerService) -> { Model },
	Clear: (self: KillerService) -> (),
	IsValidName: (self: KillerService, name: string, includeSpecial: boolean?) -> boolean,
	GetKillersName: (self: KillerService) -> { string },
	GetKillerInRound: (self: KillerService, name: string) -> Model?,
	GetRandomSpawnIndex: (self: KillerService) -> number,
	KillerSpawned: Signal.Signal<Model, number>,
	KillerCleared: Signal.Signal<string>,

	-- private
	_maid: Maid.Maid,
	_killers: { Model },
	_spawningNames: { [string]: boolean },
	_spawn: (self: KillerService, name: string, spawnIndex: number) -> TypedPromise<Model, number>,
}

return (nil :: any) :: KillerService
