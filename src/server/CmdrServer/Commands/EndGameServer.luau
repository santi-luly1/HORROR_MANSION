--!strict
local Services = game:GetService("ServerScriptService").Server

local GameLoop = require(Services.GameLoop)

return function(context)
	GameLoop:Stop()
		:andThen(function()
			context:Reply("Round ended.", Color3.fromRGB(0, 255, 0))
		end)
		:catch(function(e)
			context:Reply(e, Color3.fromRGB(255, 0, 0))
		end)

	return ""
end
