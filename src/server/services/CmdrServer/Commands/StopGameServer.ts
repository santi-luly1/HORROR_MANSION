import { CommandContext } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import RoundServiceClass from "server/services/RoundService";
import CmdrConfig from "shared/CmdrConfig";

export default (context: CommandContext, name: string) => {
	const RoundService = Dependency<RoundServiceClass>();

	if (RoundService.IsEnding()) {
		context.Reply("Round is ending, try again in a moment.", CmdrConfig.Colors.Warn);
		return "";
	}

	context.Reply("Ending round...", CmdrConfig.Colors.Info);

	RoundService.Stop(name, true)
		.andThen(() => context.Reply(`Round stopped.`, CmdrConfig.Colors.Success))
		.catch((e) => {
			warn(`[Command]: ${e}`);
			context.Reply(`Failed to start round: ${e}`, CmdrConfig.Colors.Error);
		});

	return "";
};
