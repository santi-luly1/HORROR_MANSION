/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import type { BehaviorConstructor, BehaviorModule } from "server/types/VotingService";
import Default from "./Default";

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/
class SpecialMapBehaviorClass {
	private behaviors = new Map<string, BehaviorModule>();

	public Init(): void {
		for (const child of script.GetChildren()) {
			if (child.Name === "Default") continue;

			const m = require(child as ModuleScript) as BehaviorConstructor;
			this.behaviors.set(child.Name, new m());
		}
	}

	public Get(name: string): BehaviorModule {
		return this.behaviors.get(name) ?? new Default();
	}
}

const SpecialKillerBehavior = new SpecialMapBehaviorClass();
export default SpecialKillerBehavior;
