import { CommandContext } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";
import KillerServiceClass from "server/services/KillerService";

const KillerService = Dependency<KillerServiceClass>();

export = (context: CommandContext, name: string) => {
	// FIXME: this does not verify if it is the last killer, if it is, this roound will not be skipped.
	const currentKillers = KillerService.GetCurrentKillers();
	if (currentKillers.size() === 0) {
		context.Reply("No killers found.", new Color3(1, 0.7843137255, 0)); // 255,200,0
		return "";
	}

	if (!KillerService.IsValidName(name, true)) {
		context.Reply("Invalid name.", new Color3(1, 0, 0)); // 255,0,0
		return "";
	}

	if (name === "*") {
		for (const killer of currentKillers) {
			killer.Kill();
			context.Reply(`${killer.name} was killed.`, new Color3(0, 1, 0)); // 0,255,0
		}
	} else if (name === "**") {
		const selectedKiller = currentKillers[math.random(1, currentKillers.size())];

		if (currentKillers.size() === 1) {
			selectedKiller.model.SetAttribute("skipRound", true); // dodgy fix, maybe temporary or permanent.
		}

		selectedKiller.Kill();
		context.Reply(`${selectedKiller.name} was killed.`, new Color3(0, 1, 0)); // 0,255,0
	} else {
		const targetKiller = KillerService.GetKillerInRound(name);

		if (!targetKiller) {
			context.Reply(`${name} was not found in round.`, new Color3(1, 0, 0)); // 255,0,0
			return "";
		}

		targetKiller[1].Kill(); // fix this later.
		context.Reply(`${name} was killed.`, new Color3(0, 1, 0)); // 0,255,0
	}

	return "";
};
