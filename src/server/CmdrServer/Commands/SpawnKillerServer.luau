--!strict
local Services = game:GetService("ServerScriptService").Server

local KillerController = require(Services.KillerController)

return function(context, name: string, spawnIndex: number)
	if name == "*" then
		KillerController:SpawnAll(spawnIndex)
			:andThen(function(killers)
				context:Reply(`Spawned {#killers} killers`, Color3.fromRGB(0, 255, 0))
			end)
			:catch(function(e)
				warn(`[Command]:`, e)
				context:Reply(e, Color3.fromRGB(255, 0, 0))
			end)
	else
		KillerController:SpawnKiller(name, spawnIndex)
			:andThen(function(killer, index)
				context:Reply(`Spawned '{killer.Name}' at index {index}.`, Color3.fromRGB(0, 255, 0))
			end)
			:catch(function(e)
				warn(`[Command]:`, e)
				context:Reply(`Failed to spawn '{name}': {e}`, Color3.fromRGB(255, 0, 0))
			end)
	end

	return ""
end
