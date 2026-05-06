--!strict
--<<SERVER>>--
local Debris = game:GetService("Debris")
local Maid = require("@game/ReplicatedStorage/Packages/maid")

local Speed = 100
local Duration = 9999999
local NozzleOffset = Vector3.new(0, 0.4, -1.1)

local function BreakJoints(Object: Instance)
	if not Object:IsA("BasePart") then
		for _, OtherObject in Object:GetDescendants() do
			BreakJoints(OtherObject)
		end
	else
		for _, Joint in Object:GetJoints() do
			Joint:Destroy()
		end
	end
end

local function createSound(name: string, id: string, handle: Part): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Parent = handle
	return sound
end

return function(tool: Tool, player: Player, maid: Maid.Maid)
	--Rescripted by Luckymaxer
	--[MODIFIED]

	local handle = tool:FindFirstChild("Handle") :: Part

	local Sounds = {
		Fire = createSound("Fire", "rbxassetid://130113322", handle),
		Reload = createSound("Reload", "rbxassetid://130113370", handle),
		HitFade = createSound("HitFade", "rbxassetid://130113415", handle),
	}

	local ServerControl = Instance.new("RemoteFunction")
	ServerControl.Name = "ServerControl"
	ServerControl.Parent = tool

	local ClientControl = Instance.new("RemoteFunction")
	ClientControl.Name = "ClientControl"
	ClientControl.Parent = tool

	local toolCharacter
	local toolHumanoid: Humanoid?

	local function InvokeClient(Mode: string, Value: any)
		pcall(function()
			ClientControl:InvokeClient(player, Mode, Value)
		end)
	end

	local function FindCharacterAncestor(Parent: Instance): (Model?, Humanoid?)
		if Parent and Parent ~= game:GetService("Workspace") then
			local humanoid = Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				return Parent :: Model, humanoid
			else
				return FindCharacterAncestor(Parent.Parent :: Instance)
			end
		end
		return nil, nil
	end

	local function GetTransparentsRecursive(Parent: Instance, PartsTable: { Instance }?): { Instance }
		local Parts = PartsTable or {}
		for _, v in ipairs(Parent:GetChildren()) do
			if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
				table.insert(Parts, v)
			end
			GetTransparentsRecursive(v, Parts)
		end
		return Parts
	end

	local function SelectionBoxify(Object: Instance)
		local SelectionBox = Instance.new("SelectionBox")
		SelectionBox.Adornee = Object
		SelectionBox.Color3 = Color3.fromRGB(0, 255, 255) -- "Toothpaste"
		SelectionBox.Parent = Object
		return SelectionBox
	end

	local function Light(Object: Instance)
		local light = handle:FindFirstChild("PointLight") :: PointLight
		local newLight = light:Clone()
		newLight.Range = (newLight.Range + 2)
		newLight.Parent = Object
	end

	local function FadeOutObjects(Objects: { Instance }, FadeIncrement: number)
		repeat
			local LastObject: (BasePart | Decal | Texture)?
			for _, v in ipairs(Objects) do
				if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
					v.Transparency += FadeIncrement
					LastObject = v
				end
			end
			task.wait()
		until not LastObject or LastObject.Transparency >= 1
	end

	local function Dematerialize(char: Model, humanoid: Humanoid, FirstPart: BasePart)
		if not char or not humanoid then
			return
		end

		humanoid.WalkSpeed = 0

		local Parts: { BasePart } = {}

		for _, v in ipairs(char:GetChildren()) do
			if v:IsA("BasePart") then
				v.Anchored = true
				table.insert(Parts, v)
			elseif v:IsA("LocalScript") or v:IsA("Script") then
				v:Destroy()
			end
		end

		local SelectionBoxes: { Instance } = {}

		local FirstSelectionBox = SelectionBoxify(FirstPart)
		Light(FirstPart)
		task.wait()

		for _, v in ipairs(Parts) do
			if v ~= FirstPart then
				table.insert(SelectionBoxes, SelectionBoxify(v))
				Light(v)
			end
		end

		local ObjectsWithTransparency = GetTransparentsRecursive(char)
		FadeOutObjects(ObjectsWithTransparency, 0.1)

		task.wait(0.5)

		BreakJoints(char)
		humanoid.Health = 0

		Debris:AddItem(char, 2)

		local FadeIncrement = 0.05
		task.delay(0.2, function()
			FadeOutObjects({ FirstSelectionBox }, FadeIncrement)
			if char and char.Parent then
				char:Destroy()
			end
		end)
		FadeOutObjects(SelectionBoxes, FadeIncrement)
	end

	local function Touched(Projectile: BasePart?, hit: BasePart)
		if not hit or not hit.Parent then
			return
		end

		local character = hit.Parent :: Model
		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

		if character and humanoid and character ~= toolCharacter :: Model then
			local ForceFieldExists = false
			for _, v in ipairs(character:GetChildren()) do
				if v:IsA("ForceField") then
					ForceFieldExists = true
					break
				end
			end
			if not ForceFieldExists then
				if Projectile then
					local HitFadeSound = Projectile:FindFirstChild(Sounds.HitFade.Name) :: Sound?

					local torso = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
					if HitFadeSound and torso then
						HitFadeSound.Parent = torso
						HitFadeSound:Play()
					end
				end
				Dematerialize(character, humanoid, hit)
			end
			if Projectile and Projectile.Parent then
				Projectile:Destroy()
			end
		end
	end

	local BaseShot = Instance.new("Part")
	BaseShot.Name = "Effect"
	BaseShot.BrickColor = BrickColor.new("Toothpaste")
	BaseShot.Material = Enum.Material.Plastic
	BaseShot.Shape = Enum.PartType.Block
	BaseShot.TopSurface = Enum.SurfaceType.Smooth
	BaseShot.BottomSurface = Enum.SurfaceType.Smooth
	BaseShot.Size = Vector3.new(0.2, 0.2, 3)
	BaseShot.CanCollide = false
	BaseShot.Locked = true
	SelectionBoxify(BaseShot)
	Light(BaseShot)
	local BaseShotSound = Sounds.HitFade:Clone()
	BaseShotSound.Parent = BaseShot

	local function Activated(target: Vector3)
		if tool.Enabled and toolHumanoid and toolHumanoid.Health > 0 then
			tool.Enabled = false

			InvokeClient("PlaySound", Sounds.Fire)

			local HandleCFrame = handle.CFrame
			local FiringPoint = HandleCFrame.Position + HandleCFrame:VectorToWorldSpace(NozzleOffset)
			local ShotCFrame = CFrame.lookAt(FiringPoint, target)

			local LaserShotClone = BaseShot:Clone()
			LaserShotClone.CFrame = ShotCFrame + (ShotCFrame.LookVector * (BaseShot.Size.Z / 2))
			local BodyVelocity = Instance.new("BodyVelocity")
			BodyVelocity.Velocity = ShotCFrame.LookVector * Speed
			BodyVelocity.Parent = LaserShotClone
			maid:GiveTask(LaserShotClone.Touched:Connect(function(Hit)
				if not Hit or not Hit.Parent then
					return
				end
				Touched(LaserShotClone, Hit)
			end))
			Debris:AddItem(LaserShotClone, Duration)
			LaserShotClone.Parent = workspace

			task.wait(0) -- FireSound length

			InvokeClient("PlaySound", Sounds.Reload)

			task.wait(0) -- ReloadSound length

			tool.Enabled = true
		end
	end

	ServerControl.OnServerInvoke = function(plr: Player, Mode: string, Value: any, arg: any)
		if plr ~= player or not toolHumanoid or toolHumanoid.Health == 0 or not tool.Enabled then
			return
		end
		if Mode == "Click" and Value then
			Activated(arg)
		end
	end

	maid:GiveTask(tool.Equipped:Connect(function()
		toolCharacter = player.Character or player.CharacterAdded:Wait() :: Model
		toolHumanoid = toolCharacter:FindFirstChildOfClass("Humanoid")
	end))

	maid:GiveTask(tool.Unequipped:Connect(function()
		toolCharacter = nil :: any
		toolHumanoid = nil
	end))
end
