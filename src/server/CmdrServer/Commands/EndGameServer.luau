--!strict
local Services = game:GetService("ServerScriptService").Server

local RoundController = require(Services.RoundController)

return function(context)
	context:Reply("Ending...", Color3.fromRGB(255, 200, 0))

	RoundController:Stop():catch(function(e)
		warn(`[Command]: {e}`)
		context:Reply(e, Color3.fromRGB(255, 0, 0))
	end)

	return ""
end
