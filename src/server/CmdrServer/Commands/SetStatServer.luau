--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService.Server

local PlayerDataHandler = require(Services.PlayerDataHandler)

return function(context, player: Player, stat: PlayerDataHandler.ValidStats, ammount: number)
	local ok = PlayerDataHandler:SetPlayerStat(player, stat, ammount)

	if ok then
		local msg = `Updated {player.Name}'s stat '{stat}' to {ammount}.`

		context:Reply(msg, Color3.fromRGB(0, 255))
		return --msg
	else
		local msg = `Failed to update {player.Name}'s stat '{stat}'.`

		context:Reply(msg, Color3.fromRGB(255))
		return --msg
	end
end
