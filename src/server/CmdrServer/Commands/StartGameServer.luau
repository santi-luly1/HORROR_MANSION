--!strict
local RoundService = require("@game/ServerScriptService/Server/RoundService")

return function(context, name: string)
	if RoundService:IsEnding() then
		context:Reply(`Round is ending, try again in a moment.`, Color3.fromRGB(255, 200, 0))
		return ""
	end

	context:Reply(`Ending round...`, Color3.fromRGB(100, 200, 225))

	RoundService:Begin(name, true)
		:andThen(function(killers)
			for _, killer in ipairs(killers) do
				context:Reply(`Round started with '{killer.name}'.`, Color3.fromRGB(0, 255, 0))
			end
		end)
		:catch(function(e)
			warn(`[Command]: {e}`)
			context:Reply(`Failed to start round: {e}`, Color3.fromRGB(255, 0, 0))
		end)

	return ""
end
