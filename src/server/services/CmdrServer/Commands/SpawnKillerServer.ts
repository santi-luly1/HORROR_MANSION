import { CommandContext } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import KillerServiceClass from "server/services/KillerService";
import RoundServiceClass from "server/services/RoundService";
import CmdrConfig from "shared/CmdrConfig";

export default (context: CommandContext, name: string, spawnIndex: number) => {
	const KillerService = Dependency<KillerServiceClass>();
	const RoundService = Dependency<RoundServiceClass>();

	if (RoundService.OnIntermission()) {
		context.Reply("Can't spawn killers during intermission!", CmdrConfig.Colors.Warn);
		return "";
	}
	if (RoundService.IsEnding()) {
		context.Reply("Can't spawn killers while round is ending!", CmdrConfig.Colors.Warn);
		return "";
	}

	if (name === "*") {
		KillerService.SpawnAll(spawnIndex)
			.andThen((killers) =>
				context.Reply(
					`Spawned ${killers.size()} killers out of ${KillerService.GetKillersName().size() - 2}`, // 2 deducted bc of the 2 special ones (* and **)
					CmdrConfig.Colors.Success,
				),
			)
			.catch((e) => {
				warn(`[Command]: ${e}`);
				context.Reply(`${e}`, CmdrConfig.Colors.Error);
			});
	} else {
		KillerService.SpawnKiller(name, spawnIndex)
			.andThen((killer) => context.Reply(`Spawned '${killer.name}'.`, CmdrConfig.Colors.Success))
			.catch((e) => {
				warn(`[Command]: ${e}`);
				context.Reply(`Failed to spawn: ${e}`, CmdrConfig.Colors.Error);
			});
	}

	return "";
};
