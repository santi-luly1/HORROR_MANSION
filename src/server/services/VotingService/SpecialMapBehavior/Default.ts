import { Trove } from "@rbxts/trove";
import { BehaviorModule } from "server/types/VotingService";

class DefaultClass implements BehaviorModule {
	public OnMapLoaded(mapModel: Model, trove: Trove) {
		// default no-op
	}
}

const Default = new DefaultClass();
export = Default;
