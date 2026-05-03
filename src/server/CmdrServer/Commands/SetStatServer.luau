--!strict
local PlayerDataService = require("@server/PlayerDataService")
local Types = require("@serverTypes/PlayerDataServiceTypes")

return function(context, player: Player, stat: Types.ValidStats, ammount: number)
	PlayerDataService:SetPlayerStat(player, stat, ammount)
		:andThen(function() -- we're assuming that we do not need the ok status
			context:Reply(`Updated {player.Name}'s stat '{stat}' to {ammount}.`, Color3.fromRGB(0, 255, 0))
		end)
		:catch(function(e)
			warn(`[Command]: {e}`)
			context:Reply(`Failed to update: {e}`, Color3.fromRGB(255, 0, 0))
		end)

	return ""
end
