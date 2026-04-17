--!strict
local RunService = game:GetService("RunService")
local ReplicatedPackages = game:GetService("ReplicatedStorage").Packages
local Maid = require(ReplicatedPackages.maid)
local Default = {} :: BehaviorModule

export type BehaviorModule = {
	Init: (self: BehaviorModule, model: Model, maid: Maid.Maid) -> (),
	InitAI: (
		self: BehaviorModule,
		model: Model,
		maid: Maid.Maid,
		Compute: (model: Model, maid: Maid.Maid) -> boolean -- don't really like the fact that there are multiple hard-coded typed of the same thing.
	) -> thread,
	OnKilledPlayer: (self: BehaviorModule, model: Model, victim: Model) -> (),
	Damage: (self: BehaviorModule, model: Model, humanoid: Humanoid) -> (),
	OnDamaged: (self: BehaviorModule, health: number) -> (),

	GetKillSound: (self: BehaviorModule) -> string,
	GetBonkSound: (self: BehaviorModule) -> string,
	GetBonkDelay: (self: BehaviorModule) -> number,

	_model: Model,
	_maid: Maid.Maid,
}

function Default:Init(model: Model, maid)
	self._model = model
	self._maid = maid

	local humanoid = model:FindFirstChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = 16
end

function Default:InitAI(model, maid, Compute)
	return task.spawn(function() -- this can act as an fallback.
		while model.Parent do
			local ok = Compute(model, maid)
			if ok then
				RunService.Heartbeat:Wait() -- sooo smooth
			else
				task.wait(0.5)
			end
		end
	end)
end

function Default:OnKilledPlayer(model: Model, victim: Model) -- maybe this should be private?
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

function Default:Damage(model, humanoid)
	humanoid:TakeDamage(20)

	if humanoid.Health <= 0 then
		self:OnKilledPlayer(model, humanoid.Parent :: Model)
	end
end

function Default:OnDamaged(_health)
	--print("ouch!")
end

function Default:GetBonkSound(): string
	return `rbxassetid://140110603417819`
end

function Default:GetKillSound(): string
	return `rbxassetid://139771888058836`
end

function Default:GetBonkDelay()
	return 1.5
end

return Default
