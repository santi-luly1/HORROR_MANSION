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
export interface MapData {
	Name: string;
	Thumbnail: string;
}

export interface BehaviorModule {
	OnMapLoaded: (this: BehaviorModule, mapModel: Model, trove: Trove) => void;
}

export interface SpecialMapBehaviorType {
	Init: (this: SpecialMapBehaviorType) => void;
	Get: (this: SpecialMapBehaviorType, name: string) => BehaviorModule;
}

export type BehaviorConstructor = new () => BehaviorModule;
