--!strict
local Services = game:GetService("ServerScriptService").Server

local GameLoop = require(Services.GameLoop)

return function(context)
	context:Reply("Ending...", Color3.fromRGB(255, 200, 0))

	GameLoop:Stop():catch(function(e)
		warn(`[Command]:`, e)
		context:Reply(e, Color3.fromRGB(255, 0, 0))
	end)

	return ""
end
