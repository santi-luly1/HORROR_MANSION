import { Register, Guard, Command, CommandContext, CommandGuard, CenturionType } from "@rbxts/centurion";

const isAdmin: CommandGuard = (ctx) => {
	if (ctx.executor.UserId !== game.CreatorId) {
		ctx.error("Insufficient permission!");
		return false;
	}

	return true;
};

@Register()
class KickCommand {
	@Command({
		name: "kick",
		description: "Kick a player",
		arguments: [
			{
				name: "player",
				description: "Player to kick",
				type: CenturionType.Player,
			},
		],
	})
	@Guard(isAdmin)
	kick(ctx: CommandContext, player: Player) {
		player.Kick("You have been kicked from the server.");
		ctx.reply(`Successfully kicked ${player.Name}`);
	}
}
