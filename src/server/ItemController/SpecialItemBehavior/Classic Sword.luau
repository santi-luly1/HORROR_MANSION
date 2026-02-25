--!strict
--<<SERVER>>--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Packages.maid)

local BaseUrl = "rbxassetid://"

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DamageValues = {
	BaseDamage = 5,
	SlashDamage = 10,
	LungeDamage = 30,
}

--For R15 avatars
local Animations = {
	R15Slash = 522635514,
	R15Lunge = 522638767,
}

local Grips = {
	Up = CFrame.new(0, 0, -1.70000005, 0, 0, 1, 1, 0, 0, 0, 1, 0),
	Out = CFrame.new(0, 0, -1.70000005, 0, 1, 0, 1, -0, 0, 0, 0, -1),
}

return function(tool: Tool, player: Player, maid: Maid.Maid)
	--Rescripted by Luckymaxer
	--EUROCOW WAS HERE BECAUSE I MADE THE PARTICLES AND THEREFORE THIS ENTIRE SWORD PRETTY AND LOOK PRETTY WORDS AND I'D LIKE TO DEDICATE THIS TO MY FRIENDS AND HI LUCKYMAXER PLS FIX SFOTH SWORDS TY LOVE Y'ALl
	--Updated for R15 avatars by StarWars
	--Re-updated by TakeoHonorable
	--[MODIFIED]

	local Damage = DamageValues.BaseDamage
	local ToolEquipped = false
	local LastAttack = 0
	local Connection: RBXScriptConnection?

	local Handle = tool:FindFirstChild("Handle") :: Part

	local function createSound(name: string, id: number): Sound
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = BaseUrl .. id
		sound.Parent = Handle
		return sound
	end

	local Sounds = {
		Slash = createSound("SwordSlash", 12222216),
		Lunge = createSound("SwordLunge", 12222208),
		Unsheath = createSound("Unsheath", 12222225),
	}

	local function createAnimation(name: string, id: number): Animation
		local anim = Instance.new("Animation")
		anim.Name = name
		anim.AnimationId = BaseUrl .. id
		anim.Parent = tool
		return anim
	end

	local R15SlashAnim = createAnimation("R15Slash", Animations.R15Slash)
	local R15LungeAnim = createAnimation("R15Lunge", Animations.R15Lunge)

	tool.Grip = Grips.Up
	tool.Enabled = true

	local Character: Model
	local Humanoid: Humanoid?
	local Torso: BasePart?

	local function IsTeamMate(Player1: Player?, Player2: Player?): boolean
		return (
			Player1 ~= nil
			and Player2 ~= nil
			and not Player1.Neutral
			and not Player2.Neutral
			and Player1.TeamColor == Player2.TeamColor
		)
	end

	local function UntagHumanoid(humanoid: Humanoid)
		for _, v in ipairs(humanoid:GetChildren()) do
			if v:IsA("ObjectValue") and v.Name == "creator" then
				v:Destroy()
			end
		end
	end

	local function TagHumanoid(humanoid: Humanoid, plr: Player)
		UntagHumanoid(humanoid)
		local Creator_Tag = Instance.new("ObjectValue")
		Creator_Tag.Name = "creator"
		Creator_Tag.Value = plr
		Debris:AddItem(Creator_Tag, 2)
		Creator_Tag.Parent = humanoid
	end

	local function CheckIfAlive(): boolean
		return player -- if the player spams while dead, then there's a short time where the player is nil for some reason.
			and player.Parent ~= nil
			and Character.Parent ~= nil
			and Humanoid ~= nil
			and Humanoid.Parent ~= nil
			and Humanoid.Health > 0
			and Torso ~= nil
			and Torso.Parent ~= nil
	end

	local function Blow(Hit: BasePart)
		if not Hit or not Hit.Parent or not CheckIfAlive() or not ToolEquipped then
			return
		end

		local RightArm = Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightHand")
		if not RightArm then
			return
		end

		local RightGrip = RightArm:FindFirstChild("RightGrip") :: any
		if not RightGrip or (RightGrip.Part0 ~= Handle and RightGrip.Part1 ~= Handle) then
			return
		end

		local hitCharacter = Hit.Parent :: Model
		if hitCharacter == Character then
			return
		end

		local humanoid = hitCharacter:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health == 0 then
			return
		end

		local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
		if hitPlayer and (hitPlayer == player or IsTeamMate(player, hitPlayer)) then
			return
		end

		TagHumanoid(humanoid, player)
		humanoid:TakeDamage(Damage)
	end

	local function Attack()
		Damage = DamageValues.SlashDamage
		Sounds.Slash:Play()

		if not Humanoid then
			return
		end

		if Humanoid.RigType == Enum.HumanoidRigType.R6 then
			local Anim = Instance.new("StringValue")
			Anim.Name = "toolanim"
			Anim.Value = "Slash"
			Anim.Parent = tool
		elseif Humanoid.RigType == Enum.HumanoidRigType.R15 then
			local animator = Character:WaitForChild("Humanoid"):WaitForChild("Animator") :: Animator
			local Track = animator:LoadAnimation(R15SlashAnim)
			Track:Play(0)
		end
	end

	local function Lunge()
		Damage = DamageValues.LungeDamage
		Sounds.Lunge:Play()

		if not Humanoid then
			return
		end

		if Humanoid.RigType == Enum.HumanoidRigType.R6 then
			local Anim = Instance.new("StringValue")
			Anim.Name = "toolanim"
			Anim.Value = "Lunge"
			Anim.Parent = tool
		elseif Humanoid.RigType == Enum.HumanoidRigType.R15 then
			local animator = Character:WaitForChild("Humanoid"):WaitForChild("Animator") :: Animator
			local Track = animator:LoadAnimation(R15LungeAnim)
			Track:Play(0)
		end

		task.wait(0.2)
		tool.Grip = Grips.Out
		task.wait(0.6)
		tool.Grip = Grips.Up

		Damage = DamageValues.SlashDamage
	end

	local function Activated()
		if not tool.Enabled or not ToolEquipped or not CheckIfAlive() then
			return
		end

		tool.Enabled = false
		local Tick = RunService.Stepped:Wait()

		if Tick - LastAttack < 0.2 then
			Lunge()
		else
			Attack()
		end

		LastAttack = Tick
		Damage = DamageValues.BaseDamage
		tool.Enabled = true
	end

	local function Equipped()
		Character = tool.Parent :: Model
		if not Character then
			return
		end

		player = Players:GetPlayerFromCharacter(Character)
		Humanoid = Character:FindFirstChildOfClass("Humanoid")
		Torso = (Character:FindFirstChild("Torso") or Character:FindFirstChild("HumanoidRootPart")) :: Part

		if not CheckIfAlive() then
			return
		end

		ToolEquipped = true
		Sounds.Unsheath:Play()

		if Connection then
			Connection:Disconnect()
		end
		Connection = Handle.Touched:Connect(Blow)
	end

	local function Unequipped()
		tool.Grip = Grips.Up
		ToolEquipped = false
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
	end

	maid:GiveTask(tool.Activated:Connect(Activated))
	maid:GiveTask(tool.Equipped:Connect(Equipped))
	maid:GiveTask(tool.Unequipped:Connect(Unequipped))

	maid:GiveTask(function()
		if Connection then
			Connection:Disconnect()
		end
		UntagHumanoid(Humanoid :: Humanoid)
	end)
end
