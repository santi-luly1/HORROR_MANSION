return {
	Name = "setStat";
	Aliases = {};
	Description = "Sets a player's stat to the specified amount.";
	Group = "Admin";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "The player to update.";
		},
		{
			Type = "stats";
			Name = "Stat name";
			Description = "The stat that will be updated."
		},
		{
			Type = "number";
			Name = "Ammount";
			Description = "The ammount that will be set."
		}
	};
}
