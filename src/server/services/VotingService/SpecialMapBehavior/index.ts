import { BehaviorModule, SpecialMapBehaviorType } from "server/types/VotingService";
import Default from "./Default";

class SpecialMapBehaviorClass implements SpecialMapBehaviorType {
	private default: BehaviorModule = Default;
	private behaviors: Record<string, BehaviorModule> = {};

	public Init(): void {
		script.GetChildren().forEach((module) => {
			if (module.Name === "") return;
			this.behaviors[module.Name] = require(module as ModuleScript) as BehaviorModule;
		});
	}

	public Get(name: string) {
		return this.behaviors[name] ?? this.default;
	}
}

const SpecialMapBehavior = new SpecialMapBehaviorClass();
export = SpecialMapBehavior;
