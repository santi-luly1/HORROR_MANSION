/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import type { BehaviorModule } from "server/types/KillerServiceTypes";
import Default from "./Default";

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/
class SpecialKillerBehaviorClass {
	private behaviors: Record<string, BehaviorModule> = {};
	private default: BehaviorModule = new Default();

	public Init(): void {
		for (const child of script.GetChildren()) {
			if (child.Name === "Default") continue;

			const m = require(child as ModuleScript) as BehaviorModule;
			this.behaviors[child.Name] = m;
		}
	}

	public Get(name: string): BehaviorModule {
		return this.behaviors[name] ?? this.default;
	}
}

const SpecialKillerBehavior = new SpecialKillerBehaviorClass();
export default SpecialKillerBehavior;
