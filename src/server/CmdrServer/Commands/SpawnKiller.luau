return {
	Name = "spawnkiller",
	Aliases = {"sk"},
	Description = "Spawns a killer at the specified index",
	Group = "Admin",
	Args = {
		{
			Type = "killers",
			Name = "name",
			Description = "The killer to spawn",
		},
		{
			Type = "number",
			Name = "spawnIndex",
			Description = "The spawn index (optional)",
			Default = function()
				return nil
			end,
		}
	},
}