--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService.Server

local PlayerDataHandler = require(Services.PlayerDataHandler)

return function(context, player: Player, stat: PlayerDataHandler.ValidStats, ammount: number)
	PlayerDataHandler:SetPlayerStat(player, stat, ammount)
		:andThen(function() -- we're assuming that we do not need the ok status
			context:Reply(`Updated {player.Name}'s stat '{stat}' to {ammount}.`, Color3.fromRGB(0, 255, 0))
		end)
		:catch(function(e)
			warn(e)
			context:Reply("Failed to update.", Color3.fromRGB(255, 0, 0))
		end)

	return ""
end
