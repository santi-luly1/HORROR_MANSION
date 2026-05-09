--!strict
local RunService = game:GetService("RunService")
local Registry = require("../SpecialKillerBehavior")
local simplepath = require("@game/ReplicatedStorage/Packages/simplepath")
local Hacker = {} :: Registry.BehaviorModule

function Hacker:Setup()
	local killer = self._killer
	killer.humanoid.WalkSpeed = 24

	-- Noclip
	killer.maid:GiveTask(RunService.Stepped:Connect(function()
		for _, part in ipairs(killer.model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end))

	killer:PlaySound(123437024423007, { Looped = true, Volume = 0.5 }) -- ambience

	--AI
	killer.maid:GiveTask(task.spawn(function()
		while self._killer:IsAlive() do
			RunService.Heartbeat:Wait() -- sooo smooth
			local target = simplepath.GetNearestCharacter(self._killer.humanoidRootPart.Position)
			if not target then
				task.wait(0.5) -- we wait so Roblox does not explode
				return
			end

			self._killer.humanoid:MoveTo(target:GetPivot().Position) -- this is a little bit of a bottleneck, if the player moves, the model wouldn't nice until it reaches the end.
			self._killer.humanoid.MoveToFinished:Wait()
		end
	end))
end

function Hacker:DamageVictim(humanoid)
	humanoid:TakeDamage(20)

	if humanoid.Health <= 0 then
		self:OnPlayerKill(humanoid.Parent :: Model)
	end
end

function Hacker:GetBonkSound(): number
	return 99928861785298
end

function Hacker:GetKillSound(): number
	return 4697392376
end

return Hacker
