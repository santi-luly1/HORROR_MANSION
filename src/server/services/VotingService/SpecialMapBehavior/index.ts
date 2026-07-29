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
const behaviors = new Map<string, BehaviorModule>();

for (const child of script.GetChildren()) {
	if (child.Name === "Default") continue;

	const m = require(child as ModuleScript) as BehaviorConstructor;
	behaviors.set(child.Name, new m());
}

export default {
	Get(name: string): BehaviorModule {
		return (behaviors.get(name) as BehaviorModule) ?? new Default();
	},
};
