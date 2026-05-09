return {
	Name = "removeKiller",
	Aliases = { "rk" },
	Description = "Kills the specified killer. (This can skip the round)",
	Group = "Admin",
	Args = {
		{
			Type = "killers",
			Name = "name",
			Description = "The killer to kill.",
			Default = "**",
		},
	},
}
