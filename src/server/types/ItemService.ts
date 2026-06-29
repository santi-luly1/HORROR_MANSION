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
	Behavior: any;
	Trove: Trove;
};
