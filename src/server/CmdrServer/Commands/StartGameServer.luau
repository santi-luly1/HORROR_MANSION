--!strict
local ServerStorage = game:GetService("ServerStorage")
local Services = game:GetService("ServerScriptService").Server

local Killers = ServerStorage:WaitForChild("Killers")
local GameLoop = require(Services.GameLoop)

return function(context, name: string)
	if name == "any" then
		GameLoop:Begin()
			:andThen(function(killer)
				local msg = `Round started with random killer '{killer.Name}'.`
				context:Reply(msg, Color3.fromRGB(0, 255))
			end)
			:catch(function(e)
				context:Reply(e, Color3.fromRGB(255))
			end)

		return ""
	end

	if Killers:FindFirstChild(name) then
		GameLoop:Begin(name)
			:andThen(function(killer)
				local msg = `Round started with killer '{name}'.`
				context:Reply(msg, Color3.fromRGB(0, 255))
			end)
			:catch(function(e)
				context:Reply(e, Color3.fromRGB(255))
			end)

		return ""
	end

	local msg = `'{name}' is not a valid killer.`
	context:Reply(msg, Color3.fromRGB(255))

	return ""
end
