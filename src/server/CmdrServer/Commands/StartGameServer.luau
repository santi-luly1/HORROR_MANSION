--!strict
local Services = game:GetService("ServerScriptService").Server
local GameLoop = require(Services.GameLoop)

return function(context, name: string)
	if name == "*" then
		GameLoop:Begin("*")
			:andThen(function(killers)
				context:Reply(`Started round with {#killers} killers`, Color3.fromRGB(0, 255, 0))
			end)
			:catch(function(e)
				warn(`[RoundStart] Failed:`, e)
				context:Reply(`Failed: {e}`, Color3.fromRGB(255, 0, 0))
			end)
	else
		GameLoop:Begin(name)
			:andThen(function(killers)
				for _, killer in ipairs(killers) do
					context:Reply(`Round started with '{killer.Name}'.`, Color3.fromRGB(0, 255, 0))
				end
			end)
			:catch(function(e)
				warn(`[RoundStart] Failed:`, e)
				context:Reply(`Failed to start round: {e}`, Color3.fromRGB(255, 0, 0))
			end)
	end

	return ""
end
