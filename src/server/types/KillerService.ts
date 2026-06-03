/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import { Trove } from "@rbxts/trove";

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
	id: number;
	name: string;
	model: Model;
	humanoid: Humanoid;
	humanoidRootPart: BasePart;
	hitbox: BasePart;
	alive: boolean;
	health: number;
	maxHealth: number;
	state: Enum.HumanoidStateType;
	lastDamageTime: number;
	behavior: BehaviorModule;
	trove: Trove;

	Damage: (this: Killer, amount: number) => boolean;
	Kill: (this: Killer) => void;
	IsAlive: (this: Killer) => boolean;
	TeleportTo: (this: Killer, cframe: CFrame) => void;
	PlaySound: (this: Killer, soundId: number, props?: soundProps) => Sound;
	PlayAnimation: (this: Killer, id: number) => AnimationTrack | undefined;
	SetState: (this: Killer, state: Enum.HumanoidStateType) => void;
	Destroy: (this: Killer) => void; // alias for Kill.
}

export interface BehaviorModule {
	Setup: (this: BehaviorModule) => void;
	OnPlayerKill: (this: BehaviorModule, victim: Model) => void;
	DamageVictim: (this: BehaviorModule, humanoid: Humanoid) => void;
	OnHarm: (this: BehaviorModule) => void;

	GetKillSound: (this: BehaviorModule) => number;
	GetBonkSound: (this: BehaviorModule) => number;
	GetPerishSound: (this: BehaviorModule) => number;
	GetBonkDelay: (this: BehaviorModule) => number;
}

export type BehaviorConstructor = new (killer: Killer) => BehaviorModule;
