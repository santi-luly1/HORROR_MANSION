return {
	Name = "removeKiller",
	Aliases = { "rk" },
	Description = "Kills the specified killer.",
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
