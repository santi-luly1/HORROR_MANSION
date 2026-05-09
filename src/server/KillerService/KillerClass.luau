--!strict

--[=[
	@class Killer
    @author santi-luly1
    @description Main API for killer object

    CHANGELOG: [
		04/25/26 --> Added this module.
		05/06/26 --> Added _setupDefaultBehavior to setup basic properties and signals for each killer.
	]
]=]

local Types = require("@game/ServerScriptService/Server/Types/KillerServiceTypes")

local Killer = {} :: Types.Killer
Killer.__index = Killer

function Killer:_setupStandardBehavior()
	local hum = self.humanoid

	-- humanoid
	hum.WalkSpeed = 16
	hum.UseJumpPower = true
	hum.AutoJumpEnabled = true
	hum.JumpPower = 50

	-- model setup
	self.model:SetAttribute("killer", true)

	-- subscribers
	hum.Died:Once(function()
		self:Kill()
	end)
	self.maid:GiveTask(hum.HealthChanged:Connect(function(health) -- killer is not really intended to heal anyways.
		self.health = health
		self.behavior:OnHarm()
	end))
	self.maid:GiveTask(hum:GetPropertyChangedSignal("Sit"):Connect(function()
		if not hum.Sit then
			return
		end

		task.delay(5, function()
			self.humanoid.Jump = true
		end)
	end))

	local canHit = true -- debounce
	self.maid:GiveTask(self.hitbox.Touched:Connect(function(hit)
		local char = hit.Parent
		local targetHum = char and char:FindFirstChildOfClass("Humanoid")
		if
			canHit
			and char
			and targetHum
			and targetHum.Health > 0
			and not char:FindFirstChildOfClass("ForceField")
			and not char:GetAttribute("killer")
		then
			canHit = false

			self:PlaySound(self.behavior:GetBonkSound(), { Volume = 0.5 })

			self.behavior:DamageVictim(targetHum)

			task.delay(self.behavior:GetBonkDelay(), function()
				canHit = true
			end)
		end
	end))
	self.maid:GiveTask(function()
		self:Kill()
	end)

	self.hitbox.Transparency = 0.95
end

function Killer.new(model: Model, maid): Types.Killer
	local self = (setmetatable({}, Killer) :: any) :: Types.Killer -- ugly

	--self.id = 0 -- KillerService.luau handles this.
	self.name = model.Name
	self.model = model
	self.humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	self.humanoidRootPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	self.hitbox = model:FindFirstChild("hitbox") :: BasePart
	self.alive = true
	self.maxHealth = self.humanoid.MaxHealth
	self.health = self.maxHealth
	self.lastDamageTime = 0
	--self.behavior = nil -- KillerService.luau handles this.
	self.maid = maid

	self._anims = {}
	self._animator = Instance.new("Animator")
	self._animator.Parent = self.humanoid

	self.maid:LinkToInstance(model)
	self:_setupStandardBehavior()

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

	self.humanoid.Health = 0 -- just making sure

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
		track.Volume = props.Volume or 1
		track.Looped = props.Looped or false
	end

	track.Ended:Once(function()
		track:Destroy()
	end)
	repeat
		task.wait()
	until track.IsLoaded
	track:Play()
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
