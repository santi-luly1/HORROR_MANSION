--!strict
--<<SERVER>>--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Packages.maid)

local GravityAccelerationConstant = 9.81 * 20 -- For every 20 studs is one meter on ROBLOX. 9.81 is the common accepted acceleration of gravity per a kg on earth, and is used on ROBLOX
local PercentGravity = 0.25 -- Percentage of countered acceleration due to gravity by the coil.

-- @author Quenty
-- A rewritten gravity coil script designed for understanding and reliability

local function CallOnChildren(Instance, FunctionToCall)
	-- Calls a function on each of the children of a certain object, using recursion.

	FunctionToCall(Instance)

	for _, Child in next, Instance:GetChildren() do
		CallOnChildren(Child, FunctionToCall)
	end
end

local function GetBricks(StartInstance: Instance)
	-- Returns a list of bricks (will include StartInstance)

	local List = {}

	CallOnChildren(StartInstance, function(Item)
		if Item:IsA("BasePart") then
			List[#List + 1] = Item
		end
	end)

	return List
end

return function(tool: Tool, player: Player, maid: Maid.Maid)
	--[MODIFIED]
	local AntiGravityForce = Instance.new("BodyForce")
	AntiGravityForce.Name = "GravityCoilEffect"
	AntiGravityForce.Archivable = false

	local Handle = tool:FindFirstChild("Handle") :: Part

	local CoilSound = Instance.new("Sound")
	CoilSound.Name = "CoilSound"
	CoilSound.SoundId = "rbxassetid://84428884917597"
	CoilSound.Parent = Handle

	local function UpdateGravityEffect(Character: Model)
		-- Updates the AntiGravityForce to match the force of gravity on the character

		local Bricks
		local hrp = Character:FindFirstChild("HumanoidRootPart") :: Part
		if Character:IsDescendantOf(game) and hrp and hrp:IsA("BasePart") then
			local BasePart = hrp
			Bricks = BasePart:GetConnectedParts(true) -- Recursive
		else
			warn("[UpdateGravityEffect] - Character failed to have a HumanoidRootPart or something")
			Bricks = GetBricks(Character)
		end

		local TotalMass = 0

		-- Calculate total mass of player
		for _, Part in pairs(Bricks) do
			TotalMass = TotalMass + Part:GetMass()
		end

		-- Force = Mass * Acceleration
		local ForceOnCharacter = GravityAccelerationConstant * TotalMass
		local CounteringForceMagnitude = (1 - PercentGravity) * ForceOnCharacter

		-- Set the actual value...
		AntiGravityForce.Force = Vector3.new(0, CounteringForceMagnitude, 0)
	end

	-- Connect events for player interaction
	local innerMaid = Maid.new()
	maid:GiveTask(innerMaid)
	maid:GiveTask(tool.Equipped:Connect(function()
		local Character = player.Character

		if Character then
			-- Connect events to recalculate gravity when hats are added or removed. Of course, this is not a perfect solution,
			-- as connected parts are not necessarily part of the character, but ROBLOX has no API to handle the changing of joints, and
			-- scanning the whole game for potential joints is really not worth the efficiency cost.
			innerMaid:DoCleaning()

			innerMaid:GiveTask(Character.DescendantAdded:Connect(function()
				UpdateGravityEffect(Character)
			end))

			innerMaid:GiveTask(Character.DescendantRemoving:Connect(function()
				UpdateGravityEffect(Character)
			end))

			UpdateGravityEffect(Character)
			-- Add in the force
			AntiGravityForce.Parent = Handle

			-- Play sound
			CoilSound:Play()
		else
			warn("[GravityCoil] - Somehow inexplicity failed to retrieve character")
		end
	end))

	maid:GiveTask(tool.Unequipped:Connect(function()
		-- Remove force and clean up events
		AntiGravityForce.Parent = nil
		CoilSound:Stop()
	end))
end
