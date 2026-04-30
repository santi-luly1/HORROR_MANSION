--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Registry = require(script.Parent)
local simplepath = require(ReplicatedStorage.Packages.simplepath)
local Hacker = {} :: Registry.BehaviorModule

function Hacker:Init(killer)
	self._killer = killer

	killer.humanoid.WalkSpeed = 24
	killer.humanoid.JumpPower = 0

	-- Noclip
	killer.maid:GiveTask(RunService.Stepped:Connect(function()
		for _, part in ipairs(killer.model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end))

	killer:PlaySound(123437024423007, { Looped = true, Volume = 0.5 }) -- ambience
end

function Hacker:InitAI()
	return task.spawn(function()
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

		print(`{self._killer.name}'s AI ended.`)
	end)
end

function Hacker:Damage(model, humanoid)
	humanoid:TakeDamage(20)

	if humanoid.Health <= 0 then
		self:OnPlayerKilled(model, humanoid.Parent :: Model)
	end
end

function Hacker:GetBonkSound(): number
	return 99928861785298
end

function Hacker:GetKillSound(): number
	return 4697392376
end

return Hacker
