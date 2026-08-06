import { CommandDefinition } from "@rbxts/cmdr";

export = identity<CommandDefinition>({
	Name: "spawnKiller",
	Aliases: ["sk"],
	Description: "Spawns a killer at the specified index.",
	Group: "Admin",
	Args: [
		{
			Type: "killers",
			Name: "name",
			Description: "The killer to spawn.",
			Default: "**",
		},
		{
			Type: "number",
			Name: "spawnIndex",
			Description: "The spawn index.",
			Default: -1,
		},
	],
});
