/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import type { BehaviorConstructor } from "server/types/KillerService";
import Default from "./Default";

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/
class SpecialKillerBehaviorClass {
	private behaviors = new Map<string, BehaviorConstructor>();

	public Init(): void {
		for (const child of script.GetChildren()) {
			if (child.Name === "Default") continue;

			const m = require(child as ModuleScript) as BehaviorConstructor;
			this.behaviors.set(child.Name, m);
		}
	}

	public Get(name: string): BehaviorConstructor {
		return this.behaviors.get(name) ?? Default;
	}
}

const SpecialKillerBehavior = new SpecialKillerBehaviorClass();
export default SpecialKillerBehavior;
