import { BehaviorModule, SpecialMapBehaviorType } from "server/types/VotingService";
import Default from "./Default";

class SpecialMapBehaviorClass extends SpecialMapBehaviorType {
	private _default: BehaviorModule;
	private _behaviors: Record<string, BehaviorModule>;

	public Init(this: SpecialMapBehaviorType) {
		for (const [, module] of pairs(script.GetChildren())) {
			if (module.Name === "") continue;
			this._behaviors[module.Name] = require(module as ModuleScript) as BehaviorModule;
		}
	}

	public Get(this: SpecialMapBehaviorType, name: string) {
		return this._behaviors[name] ?? this._default;
	}
}

const SpecialMapBehavior = new SpecialMapBehaviorClass();
export = SpecialMapBehavior;
