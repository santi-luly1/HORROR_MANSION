--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Registry = require(script.Parent)
local simplepath = require(ReplicatedStorage.Packages.simplepath)
local Hacker = {} :: Registry.BehaviorModule

function Hacker:Init(model: Model, maid)
	self._model = model
	self._maid = maid

	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid

	humanoid.WalkSpeed = 24
	humanoid.JumpPower = 0

	-- Noclip
	maid:GiveTask(RunService.Stepped:Connect(function()
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end))

	local ambience = Instance.new("Sound")
	ambience.Name = "Ambience"
	ambience.SoundId = "rbxassetid://123437024423007"
	ambience.Looped = true
	ambience.Volume = 0.5
	ambience.Parent = hrp
	ambience:Play()

	maid:GiveTask(ambience)
end

function Hacker:InitAI(model)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: Part
	local humanoid = model:FindFirstChild("Humanoid") :: Humanoid
	return task.spawn(function()
		while model.Parent do
			RunService.Heartbeat:Wait() -- sooo smooth
			local target = simplepath.GetNearestCharacter(hrp.Position)
			if not target then
				task.wait(0.5) -- we wait so Roblox does not explode
				return
			end

			humanoid:MoveTo(target:GetPivot().Position) -- this is a little bit of a bottleneck, if the player moves, the model wouldn't nice until it reaches the end.
			humanoid.MoveToFinished:Wait()
		end
	end)
end

function Hacker:OnKilledPlayer(model: Model, victim: Model)
	local track = Instance.new("Sound")
	track.Parent = model.PrimaryPart
	track.Volume = 2 -- a bit loud?
	track.Ended:Once(function()
		track:Destroy()
	end)
	track.SoundId = self:GetKillSound()
	track:Play()

	warn(`{model.Name} says L to {victim.Name}`)
end

function Hacker:Damage(model, humanoid)
	humanoid:TakeDamage(20)

	if humanoid.Health <= 0 then
		self:OnKilledPlayer(model, humanoid.Parent :: Model)
	end
end

function Hacker:OnDamaged(health)
	return Registry._default:OnDamaged(health)
end

function Hacker:GetBonkSound(): string
	return `rbxassetid://99928861785298`
end

function Hacker:GetKillSound(): string
	return `rbxassetid://4697392376`
end

function Hacker:GetBonkDelay()
	return Registry._default:GetBonkDelay()
end

return Hacker
