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
export default {
	Get(name: string): BehaviorConstructor {
		return behaviors.get(name) ?? Default;
	},
};

const behaviors = new Map<string, BehaviorConstructor>();

for (const child of script.GetChildren()) {
	if (child.Name === "Default") continue;

	const mod = require(child as ModuleScript) as unknown;
	const behavior = (mod as { default?: unknown }).default ?? mod;
	behaviors.set(child.Name, behavior as BehaviorConstructor);
}
