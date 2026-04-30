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

export type Killer = {
	__index: Killer,

	id: number,
	name: string,
	model: Model,
	humanoid: Humanoid,
	humanoidRootPart: BasePart,
	hitbox: BasePart,
	alive: boolean,
	health: number,
	maxHealth: number,
	state: string,
	lastDamageTime: number,
	behavior: BehaviorModule,
	maid: Maid.Maid,
	_anims: { Animation },
	_animator: Animator,

	new: (model: Model, maid: Maid.Maid) -> Killer,
	Damage: (self: Killer, amount: number) -> boolean,
	Kill: (self: Killer) -> (),
	IsAlive: (self: Killer) -> boolean,
	TeleportTo: (self: Killer, cframe: CFrame) -> (),
	PlaySound: (self: Killer, soundId: number, props: { [string]: string | boolean | number }?) -> Sound,
	PlayAnimation: (self: Killer, id: number) -> AnimationTrack?,
	SetState: (self: Killer, state: string) -> (),
	Destroy: (self: Killer) -> (), -- alias for Kill.
}

export type BehaviorModule = {
	new: (self: BehaviorModule, killer: Killer) -> BehaviorModule,
	Init: (self: BehaviorModule, killer: Killer) -> (),
	InitAI: (self: BehaviorModule) -> thread,
	OnPlayerKilled: (self: BehaviorModule, model: Model, victim: Model) -> (),
	Damage: (self: BehaviorModule, model: Model, humanoid: Humanoid) -> (),
	OnDamaged: (self: BehaviorModule, health: number) -> (),

	GetKillSound: (self: BehaviorModule) -> number,
	GetBonkSound: (self: BehaviorModule) -> number,
	GetBonkDelay: (self: BehaviorModule) -> number,
	GetPerishSound: (self: BehaviorModule) -> number,

	__index: BehaviorModule,
	_killer: Killer,
}

export type KillerService = _SERVICE.SERVICE<KillerService> & {
	-- public API
	SpawnKiller: (self: KillerService, name: string, spawnIndex: number) -> TypedPromise<Killer>,
	SpawnKillers: (self: KillerService, names: { string }, spawnIndex: number) -> TypedPromise<{ Killer }>,
	SpawnAll: (self: KillerService, spawnIndex: number) -> TypedPromise<{ Killer }>,
	GetCurrentKillers: (self: KillerService) -> { Killer },
	Clear: (self: KillerService) -> (),
	IsValidName: (self: KillerService, name: string, includeSpecial: boolean?) -> boolean,
	GetKillersName: (self: KillerService) -> { string },
	GetKillerInRound: (self: KillerService, name: string) -> { Killer }?,
	GetRandomSpawnIndex: (self: KillerService) -> number,

	-- signals
	KillerSpawned: Signal.Signal<Killer>,
	KillerCleared: Signal.Signal<string, string?>, -- name, id (optional)
	KillerDamaged: Signal.Signal<string, number, Instance?>, -- id, amount, source
	KillerDied: Signal.Signal<string, string, Instance?>, -- id, name, source

	-- private
	_spawn: (self: KillerService, name: string, spawnIndex: number) -> TypedPromise<Killer>,
	_maid: Maid.Maid,
	_killers: { [number]: Killer },
	_spawningNames: { [string]: boolean },
}

return (nil :: any) :: KillerService
