--!strict
local ServerStorage = game:GetService("ServerStorage")
local Services = game:GetService("ServerScriptService").Server

local KillerController = require(Services.KillerController)
local Killers = ServerStorage:WaitForChild("Killers")

return function(context, name: string, spawnIndex: number?)
	if typeof(spawnIndex) == "function" then
		spawnIndex = nil -- function returns nil anyways.
	end

	if name == "any" then
		KillerController:SpawnKiller(nil, spawnIndex)
			:andThen(function(killer, index)
				local msg = `Spawned random killer {killer.Name} at index {index}.`
				context:Reply(msg, Color3.fromRGB(0, 255))
			end)
			:catch(function(e)
				context:Reply(e, Color3.fromRGB(255))
			end)

		return ""
	end

	if Killers:FindFirstChild(name) then
		KillerController:SpawnKiller(name, spawnIndex)
			:andThen(function(killer, index)
				local msg = `Spawned {name} at index {index}.`
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
