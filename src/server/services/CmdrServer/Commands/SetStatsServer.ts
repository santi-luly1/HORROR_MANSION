import { CommandContext } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import PlayerDataServiceClass from "server/services/PlayerDataService";
import type { ValidStats } from "server/types/PlayerDataService";
import CmdrConfig from "shared/CmdrConfig";

export default (context: CommandContext, player: Player, stat: ValidStats, ammount: number) => {
	const PlayerDataService = Dependency<PlayerDataServiceClass>();

	PlayerDataService.SetPlayerStat(player, stat, ammount)
		.andThen(() =>
			context.Reply(`Updated ${player.Name}'s stat '${stat}' to ${ammount}.`, CmdrConfig.Colors.Success),
		)
		.catch((e) => {
			warn(`[Command]: ${e}`);
			context.Reply(`Failed to update: ${e}`, CmdrConfig.Colors.Error);
		});

	return "";
};
