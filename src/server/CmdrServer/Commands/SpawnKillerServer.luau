--!strict
local killersCount = #game:GetService("ServerStorage").Killers:GetChildren()
local Services = game:GetService("ServerScriptService").Server

local KillerService = require(Services.KillerService)
local RoundService = require(Services.RoundService)

return function(context, name: string, spawnIndex: number)
	if RoundService:OnIntermission() then
		context:Reply(`Can't spawn killers during intermission!`, Color3.fromRGB(255, 200, 0))
		return ""
	end
	if RoundService:IsEnding() then
		context:Reply(`Can't spawn killers while round is ending!`, Color3.fromRGB(255, 200, 0))
		return ""
	end

	if name == "*" then
		KillerService:SpawnAll(spawnIndex)
			:andThen(function(killers)
				context:Reply(`Spawned {#killers} killers out of {killersCount}`, Color3.fromRGB(0, 255, 0))
			end)
			:catch(function(e)
				warn(`[Command]: {e}`)
				context:Reply(e, Color3.fromRGB(255, 0, 0))
			end)
	else
		KillerService:SpawnKiller(name, spawnIndex)
			:andThen(function(killer)
				context:Reply(`Spawned '{killer.name}'.`, Color3.fromRGB(0, 255, 0))
			end)
			:catch(function(e)
				warn(`[Command]: {e}`)
				context:Reply(`Failed to spawn: {e}`, Color3.fromRGB(255, 0, 0))
			end)
	end

	return ""
end
