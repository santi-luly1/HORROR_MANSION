return {
	Name = "startGame",
	Aliases = { "start", "skip", "skipRound" },
	Description = "Starts a new fresh round. (This will skip the current one)",
	Group = "Admin",
	Args = {
		{
			Type = "killers",
			Name = "killer",
			Description = "Start with a preferred killer.",
			Default = "**",
		},
	},
}
