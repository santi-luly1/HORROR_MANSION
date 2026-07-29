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
export type ItemData = {
	Price: number;
	Name: string;
	TextureId: string;
};

export type ActiveItem = {
	Tool: Tool;
	Player: Player;
	Behavior: BehaviorModule;
	Trove: Trove;
};

export interface BehaviorModule {
	Setup: (this: BehaviorModule) => void;
	Destroy: (this: BehaviorModule) => void;
	GetPlayerFromEquipped: (this: BehaviorModule) => Player | undefined;
}

export type BehaviorConstructor = new (tool: Tool) => BehaviorModule;
