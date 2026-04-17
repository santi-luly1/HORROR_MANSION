--!strict
--<<SERVER>>--
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Packages.maid)

return function(tool: Tool, player: Player, maid: Maid.Maid)
	-- [Programmed by abrah_m]
	-- [MODIFIED]
	local Debounce = false
	local CanDamage = false

	local Character = player.Character or player.CharacterAdded:Wait() :: Model
	local CharacterSwingTrack
	local SwingAnimation = Instance.new("Animation")
	SwingAnimation.AnimationId = "rbxassetid://32659706"

	local function createSound(name: string, soundId: string): Sound
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = soundId
		sound.Parent = tool
		return sound
	end

	local SwingSound = createSound("Swing", "rbxassetid://536642316")
	local BanSound = createSound("Ban", "rbxassetid://147722910")

	maid:GiveTask(tool.Equipped:Connect(function()
		Character = player.Character or player.CharacterAdded:Wait()
		local animator = Character:WaitForChild("Humanoid"):WaitForChild("Animator") :: Animator
		CharacterSwingTrack = animator:LoadAnimation(SwingAnimation)
	end))

	maid:GiveTask(tool.Unequipped:Connect(function()
		if CharacterSwingTrack then
			CharacterSwingTrack:Stop()
		end
	end))

	maid:GiveTask(tool.Activated:Connect(function()
		if Debounce then
			return
		end

		Debounce = true
		CanDamage = true

		if CharacterSwingTrack then
			CharacterSwingTrack:Play()
		end

		SwingSound:Play()

		local handle = tool:FindFirstChild("Handle") :: MeshPart
		if not handle then
			Debounce = false
			return
		end

		local touchConnection
		touchConnection = handle.Touched:Connect(function(hit)
			if not CanDamage then
				return
			end

			local targetChar = hit.Parent :: Instance
			local humanoid = targetChar:FindFirstChildOfClass("Humanoid") :: Humanoid
			local hrp = targetChar:FindFirstChild("HumanoidRootPart") :: Part

			if not humanoid or not hrp then
				return
			end
			if humanoid.Health <= 0 then
				return
			end

			if targetChar == Character then
				return
			end

			CanDamage = false

			BanSound:Play()

			local Explosion = Instance.new("Explosion")
			Explosion.BlastRadius = 10
			Explosion.BlastPressure = 0
			Explosion.Position = hrp.Position
			Explosion.Parent = workspace

			humanoid.Health = 0

			for _, obj in ipairs(targetChar:GetDescendants()) do
				if obj:IsA("Motor6D") and (obj.Parent :: Instance).Name ~= "HumanoidRootPart" then
					local part0 = obj.Part0
					local part1 = obj.Part1

					if part0 and part1 then
						local Socket = Instance.new("BallSocketConstraint")
						local a1 = Instance.new("Attachment")
						local a2 = Instance.new("Attachment")

						a1.Parent = part0
						a2.Parent = part1
						Socket.Parent = part1

						Socket.Attachment0 = a1
						Socket.Attachment1 = a2

						a1.CFrame = obj.C0
						a2.CFrame = obj.C1

						Socket.LimitsEnabled = true
						Socket.TwistLimitsEnabled = true

						obj:Destroy()
					end
				end
			end

			local BodyVelocity = Instance.new("BodyVelocity")
			BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 10000000
			BodyVelocity.Velocity = (Character:FindFirstChild("HumanoidRootPart") :: Part).CFrame.LookVector * 1000
			BodyVelocity.Parent = hrp

			Debris:AddItem(BodyVelocity, 0.1)
		end)

		if CharacterSwingTrack then
			CharacterSwingTrack.Stopped:Wait()
		else
			task.wait(0.5) -- fallback
		end

		touchConnection:Disconnect()

		CanDamage = false
		task.wait(0.1)
		Debounce = false
	end))
end
