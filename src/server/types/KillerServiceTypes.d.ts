/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import Maid from "@rbxts/maid";
import Signal from "@rbxts/signal";
import _SERVICE from "./_SERVICE";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/

export interface soundProps {
	Volume?: number;
	Looped?: boolean;
}
export interface Killer {
	__index: Killer;

	id: number;
	name: string;
	model: Model;
	humanoid: Humanoid;
	humanoidRootPart: BasePart;
	hitbox: BasePart;
	alive: boolean;
	health: number;
	maxHealth: number;
	state: string;
	lastDamageTime: number;
	behavior: BehaviorModule;
	maid: Maid;
	_anims: Animation[];
	_animator: Animator;

	new: (model: Model, maid: Maid) => Killer;
	Damage: (this: Killer, amount: number) => boolean;
	Kill: (this: Killer) => void;
	IsAlive: (this: Killer) => boolean;
	TeleportTo: (this: Killer, cframe: CFrame) => void;
	PlaySound: (this: Killer, soundId: number, props?: soundProps) => Sound;
	PlayAnimation: (this: Killer, id: number) => AnimationTrack | undefined;
	SetState: (this: Killer, state: string) => void;
	Destroy: (this: Killer) => void; // alias for Kill.

	_setupStandardBehavior: (this: Killer) => void;
}

export interface BehaviorModule {
	new: (this: BehaviorModule, killer: Killer) => BehaviorModule;
	Setup: (this: BehaviorModule) => void;
	OnPlayerKill: (this: BehaviorModule, victim: Model) => void;
	DamageVictim: (this: BehaviorModule, humanoid: Humanoid) => void;
	OnHarm: (this: BehaviorModule) => void;

	GetKillSound: (this: BehaviorModule) => number;
	GetBonkSound: (this: BehaviorModule) => number;
	GetPerishSound: (this: BehaviorModule) => number;
	GetBonkDelay: (this: BehaviorModule) => number;

	__index: BehaviorModule;
	_killer: Killer;
}

export interface KillerServiceMembers {
	// public API
	SpawnKiller: (this: KillerServiceMembers, name: string, spawnIndex: number) => Promise<Killer>;
	SpawnKillers: (this: KillerServiceMembers, names: string[], spawnIndex: number) => Promise<Killer[]>;
	SpawnAll: (this: KillerServiceMembers, spawnIndex: number) => Promise<Killer[]>;
	GetCurrentKillers: (this: KillerServiceMembers) => Killer[];
	Clear: (this: KillerServiceMembers) => void;
	IsValidName: (this: KillerServiceMembers, name: string, includeSpecial?: boolean) => boolean;
	GetKillersName: (this: KillerServiceMembers) => string[];
	GetKillerInRound: (this: KillerServiceMembers, name: string) => Killer[] | undefined;
	GetRandomSpawnIndex: (this: KillerServiceMembers) => number;

	// signals
	KillerSpawned: Signal;
	KillerCleared: Signal;
	KillerDamaged: Signal;
	KillerDied: Signal;

	// private
	_spawn: (this: KillerServiceMembers, name: string, spawnIndex: number) => Promise<Killer>;
	_maid: Maid;
	_killers: Record<number, Killer>;
	_spawningNames: Record<number, string>;
}

export type KillerServiceTypes = _SERVICE.Service<KillerServiceMembers>;

declare const _default: KillerServiceTypes;
export default _default;
