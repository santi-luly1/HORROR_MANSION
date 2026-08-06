import { CommandContext } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import KillerService from "server/services/KillerService";
import CmdrConfig from "shared/CmdrConfig";

export = (context: CommandContext, name: string) => {
	const killerService = Dependency<KillerService>();

	// FIXME: this does not verify if it is the last killer, if it is, this roound will not be skipped.
	const currentKillers = killerService.GetCurrentKillers();
	if (currentKillers.size() === 0) {
		context.Reply("No killers found.", CmdrConfig.Colors.Warn);
		return "";
	}

	if (!killerService.IsValidName(name, true)) {
		context.Reply("Invalid name.", CmdrConfig.Colors.Error);
		return "";
	}

	if (name === "*") {
		for (const killer of currentKillers) {
			killer.Kill();
			context.Reply(`${killer.name} was killed.`, CmdrConfig.Colors.Success);
		}
	} else if (name === "**") {
		const selectedKiller = currentKillers[math.random(1, currentKillers.size())];

		if (currentKillers.size() === 1) selectedKiller.model.SetAttribute("skipRound", true); // dodgy fix, maybe temporary or permanent.

		selectedKiller.Kill();
		context.Reply(`${selectedKiller.name} was killed.`, CmdrConfig.Colors.Success);
	} else {
		const targetKiller = killerService.GetKillerInRound(name);

		if (!targetKiller) {
			context.Reply(`${name} was not found in round.`, CmdrConfig.Colors.Error);
			return "";
		}

		targetKiller[1].Kill(); // fix this later.
		context.Reply(`${name} was killed.`, CmdrConfig.Colors.Success);
	}

	return "";
};
