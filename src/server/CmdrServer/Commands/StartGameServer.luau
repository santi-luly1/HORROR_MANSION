--!strict
local Services = game:GetService("ServerScriptService").Server
local GameLoop = require(Services.GameLoop)

return function(context, name: string)
	GameLoop:Begin(name)
		:andThen(function(killers)
			for _, killer in ipairs(killers) do
				context:Reply(`Round started with '{killer.Name}'.`, Color3.fromRGB(0, 255, 0))
			end
		end)
		:catch(function(e)
			warn(`[Command]:`, e)
			context:Reply(`Failed to start round: {e}`, Color3.fromRGB(255, 0, 0))
		end)

	return ""
end
