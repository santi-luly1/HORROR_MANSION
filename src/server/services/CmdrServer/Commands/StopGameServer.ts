import { CommandContext } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import RoundServiceClass from "server/services/RoundService";

const RoundService = Dependency<RoundServiceClass>();

export default (context: CommandContext, name: string) => {
	if (RoundService.IsEnding()) {
		context.Reply("Round is ending, try again in a moment.", new Color3(1, 0.7843137255, 0));
		return "";
	}

	context.Reply("Ending round...", new Color3(0.3921568627, 0.7843137255, 0.9019607843)); // 100,200,225

	RoundService.Stop(name, true)
		.andThen((killers) => {
			context.Reply(`Round stopped.`, new Color3(0, 1, 0));
		})
		.catch((e) => {
			warn(`[Command]: ${e}`);
			context.Reply(`Failed to start round: ${e}`, new Color3(1, 0, 0));
		});

	return "";
};
