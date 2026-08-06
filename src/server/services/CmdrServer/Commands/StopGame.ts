import { CommandDefinition } from "@rbxts/cmdr";

export = identity<CommandDefinition>({
	Name: "stopGame",
	Aliases: ["stop", "skip", "skipRound"],
	Description: "Stops the  round. (This will skip the current one)",
	Group: "Admin",
	Args: [
		{
			Type: "killers",
			Name: "killer",
			Description: "Start with a preferred killer.",
			Default: "**",
		},
	],
});
