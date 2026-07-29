// ------------------------------------------------------------------------------ Please nerf all gears inside this game, as for now, all of them can basically one-shot the killers.

import type { BehaviorConstructor } from "server/types/ItemService";

export default {
	Get(name: string): BehaviorConstructor {
		return behaviors.get(name) as BehaviorConstructor;
	},
};

const behaviors = new Map<string, BehaviorConstructor>();

for (const child of script.GetChildren()) {
	if (child.Name === "Default") continue;

	const mod = require(child as ModuleScript) as unknown;
	const behavior = (mod as { default?: unknown }).default ?? mod;
	behaviors.set(child.Name, behavior as BehaviorConstructor);
}
