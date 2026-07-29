import { CommandContext } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import KillerServiceClass from "server/services/KillerService";
import RoundServiceClass from "server/services/RoundService";

const KillerService = Dependency<KillerServiceClass>();
const RoundService = Dependency<RoundServiceClass>();

export default (context: CommandContext, name: string, spawnIndex: number) => {
	if (RoundService.OnIntermission()) {
		context.Reply("Can't spawn killers during intermission!", new Color3(1, 0.7843137255, 0)); // 255,200,0
		return "";
	}
	if (RoundService.IsEnding()) {
		context.Reply("Can't spawn killers while round is ending!", new Color3(1, 0.7843137255, 0)); // 255,200,0
		return "";
	}

	if (name === "*") {
		KillerService.SpawnAll(spawnIndex)
			.andThen((killers) => {
				context.Reply(
					`Spawned ${killers.size()} killers out of ${KillerService.GetKillersName().size() - 2}`,
					new Color3(0, 1, 0),
				);
			})
			.catch((e) => {
				warn(`[Command]: ${e}`);
				context.Reply(`${e}`, new Color3(1, 0, 0));
			});
	} else {
		KillerService.SpawnKiller(name, spawnIndex)
			.andThen((killer) => {
				context.Reply(`Spawned '${killer.name}'.`, new Color3(0, 1, 0));
			})
			.catch((e) => {
				warn(`[Command]: ${e}`);
				context.Reply(`Failed to spawn: ${e}`, new Color3(1, 0, 0));
			});
	}

	return "";
};
