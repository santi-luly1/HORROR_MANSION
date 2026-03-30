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

export type KillerController = _SERVICE.SERVICE<KillerController> & {
	-- public API
	SpawnKillers: (self: KillerController, names: { string }, spawnIndex: number) -> TypedPromise<{ Model }>,
	SpawnAll: (self: KillerController, spawnIndex: number) -> TypedPromise<{ Model }>,
	SpawnKiller: (self: KillerController, name: string, spawnIndex: number) -> TypedPromise<Model, number>,
	GetCurrentKillers: (self: KillerController) -> { Model },
	Clear: (self: KillerController) -> (),
	IsValidName: (self: KillerController, name: string) -> boolean,
	GetKillersName: (self: KillerController) -> { string },
	GetRandomIndex: (self: KillerController) -> number,
	KillerSpawned: Signal.Signal<Model, number>,
	KillerCleared: Signal.Signal<string>,

	-- private
	_maid: Maid.Maid,
	_killers: { Model },
	_spawningNames: { [string]: boolean },
	_spawn: (self: KillerController, name: string, spawnIndex: number) -> TypedPromise<Model, number>,
}

return (nil :: any) :: KillerController
