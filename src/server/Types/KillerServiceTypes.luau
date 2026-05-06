--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Maid = require("@game/ReplicatedStorage/Packages/maid")
local Promise = require("@game/ReplicatedStorage/Packages/promise")
local Signal = require("@game/ReplicatedStorage/Packages/signal")
local _SERVICE = require("@game/ServerScriptService/Server/Types/_SERVICE")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

type soundProps = {
	Volume: number?,
	Looped: boolean?,
}
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
	PlaySound: (self: Killer, soundId: number, props: soundProps?) -> Sound,
	PlayAnimation: (self: Killer, id: number) -> AnimationTrack?,
	SetState: (self: Killer, state: string) -> (),
	Destroy: (self: Killer) -> (), -- alias for Kill.

	_setupStandardBehavior: (self: Killer) -> (),
}

export type BehaviorModule = {
	new: (self: BehaviorModule, killer: Killer) -> BehaviorModule,
	Setup: (self: BehaviorModule) -> (),
	OnPlayerKill: (self: BehaviorModule, victim: Model) -> (),
	DamageVictim: (self: BehaviorModule, humanoid: Humanoid) -> (),
	OnHarm: (self: BehaviorModule) -> (),

	GetKillSound: (self: BehaviorModule) -> number,
	GetBonkSound: (self: BehaviorModule) -> number,
	GetPerishSound: (self: BehaviorModule) -> number,
	GetBonkDelay: (self: BehaviorModule) -> number,

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
