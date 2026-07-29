/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import { Trove } from "@rbxts/trove";
import { BehaviorModule } from "server/types/VotingService";

/*
--------------------------------------------------------------------
--- Default (base) behavior
--------------------------------------------------------------------
*/
export default class Default implements BehaviorModule {
	constructor() {}
	public OnMapLoaded(this: BehaviorModule, mapModel: Model, trove: Trove) {
		// no-op
	}
}
