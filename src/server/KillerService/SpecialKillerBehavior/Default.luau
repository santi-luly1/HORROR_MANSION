--!strict
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local KillerServiceTypes = require(ServerScriptService.Server.Types.KillerServiceTypes)
local Default = {} :: KillerServiceTypes.BehaviorModule
Default.__index = Default

function Default.new(self, killer)
	local obj = (setmetatable({}, self) :: any) :: KillerServiceTypes.BehaviorModule -- ugly
	obj._killer = killer
	return obj
end

function Default:Init(killer)
	self._killer = killer

	killer.humanoid.WalkSpeed = 16
end

function Default:InitAI()
	return task.spawn(function() -- this can act as an fallback.
		local compute = require(script.Parent.Parent.Compute) -- make it not so hardcoded
		while self._killer:IsAlive() do
			local ok = compute(self._killer.model, self._killer.maid)
			if ok then
				RunService.Heartbeat:Wait() -- sooo smooth
			else
				task.wait(0.5)
			end
		end
	end)
end

function Default:OnPlayerKilled(model: Model, victim: Model) -- maybe this should be private?
	self._killer:PlaySound(self:GetKillSound())

	warn(`{model.Name} says L to {victim.Name}`)
end

function Default:Damage(model, humanoid)
	humanoid:TakeDamage(20)

	if humanoid.Health <= 0 then
		self:OnPlayerKilled(model, humanoid.Parent :: Model)
	end
end

function Default:OnDamaged(_health)
	--print("ouch!")
end

function Default:GetBonkSound(): number
	return 140110603417819
end

function Default:GetKillSound(): number
	return 139771888058836
end

function Default:GetBonkDelay()
	return 1.5
end

function Default:GetPerishSound(): number
	return 0
end

return Default
