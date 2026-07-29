import { CommandContext } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import PlayerDataServiceClass from "server/services/PlayerDataService";
import type { ValidStats } from "server/types/PlayerDataService";

const PlayerDataService = Dependency<PlayerDataServiceClass>();

export default (context: CommandContext, player: Player, stat: ValidStats, ammount: number) => {
	PlayerDataService.SetPlayerStat(player, stat, ammount)
		.andThen(() => {
			context.Reply(`Updated ${player.Name}'s stat '${stat}' to ${ammount}.`, new Color3(0, 1, 0));
		})
		.catch((e) => {
			warn(`[Command]: ${e}`);
			context.Reply(`Failed to update: ${e}`, new Color3(1, 0, 0));
		});

	return "";
};
