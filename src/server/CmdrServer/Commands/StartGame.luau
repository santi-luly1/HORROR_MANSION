return {
	Name = "startGame",
	Aliases = {"start"},
	Description = "Starts a new fresh round.",
	Group = "Admin",
	Args = {
		{
			Type = "killers",
			Name = "killer",
			Description = "Start with a preferred killer (optional).",
			Default = "any",
		}
	},
}