--!strict

--[=[
	@class Killer
    @author santi-luly1
    @description Main API for killer object

    CHANGELOG: [
		04/25/26 --> Added this module.
	]
]=]

local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ServerScriptService.Server.Types.KillerServiceTypes)

local Killer = {} :: Types.Killer
Killer.__index = Killer

function Killer.new(model: Model, maid): Types.Killer
	local self = (setmetatable({}, Killer) :: any) :: Types.Killer -- ugly

	self.id = 0 -- KillerService.luau handles this.
	self.name = model.Name
	self.model = model
	self.humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	self.humanoidRootPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	self.hitbox = model:FindFirstChild("hitbox") :: BasePart
	self.alive = true
	self.maxHealth = self.humanoid.MaxHealth
	self.health = self.maxHealth
	self.lastDamageTime = 0
	self.behavior = nil :: any -- KillerService.luau handles this.
	self.maid = maid

	self._anims = {}
	self._animator = Instance.new("Animator")
	self._animator.Parent = self.humanoid

	self.maid:LinkToInstance(model)

	return self
end

function Killer:IsAlive()
	return self.alive
end

function Killer:Damage(amount: number)
	if not self.alive then
		return false
	end

	self.lastDamageTime = os.clock()
	self.health = math.clamp(self.health - amount, 0, self.maxHealth)
	self.humanoid.Health = self.health
	self.behavior:OnDamaged(self.health)

	self:PlaySound(self.behavior:GetBonkSound(), { Volume = 0.5 })

	if self.health <= 0 then
		self:Kill()
	end

	return true
end

function Killer:Kill()
	if not self.alive then
		return
	end
	self.alive = false

	self:PlaySound(self.behavior:GetPerishSound(), { Volume = 1.0 })

	self.maid:DoCleaning()

	task.delay(10, function() -- this 10 should be the intermission time, hardcoded for now.
		if self.model and self.model.Parent then
			self.model:Destroy()
		end
	end)
end

function Killer:TeleportTo(cframe: CFrame)
	self.humanoidRootPart.CFrame = cframe
end

function Killer:PlaySound(soundId: number, props)
	local track = Instance.new("Sound")
	track.Parent = self.humanoidRootPart
	track.SoundId = `rbxassetid://{soundId}`
	if props then
		for prop, value in props do
			track[prop] = value -- FIXME: TypeError: Attempting a dynamic property access on type 'Sound' is unsafe and may cause exceptions at runtime
		end
	end
	track.Ended:Once(function()
		track:Destroy()
	end)
	track:Play()
	self.maid:GiveTask(track) -- would this really be necessary?
	return track
end

function Killer:PlayAnimation(id: number)
	if not self._anims[id] then
		self._anims[id] = Instance.new("Animation")
		self._anims[id].AnimationId = `rbxassetid://{id}`
	end

	local animTrack = self._animator:LoadAnimation(self._anims[id])
	animTrack:Play()
	self.maid:GiveTask(function()
		if animTrack.IsPlaying then
			animTrack:Stop()
		end
	end)

	return animTrack
end

Killer.Destroy = Killer.Kill -- alias.

return Killer
