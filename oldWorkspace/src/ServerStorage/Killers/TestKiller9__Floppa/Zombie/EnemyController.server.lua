local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local animation1 = script.Parent.Parent.Animations:WaitForChild('WalkAnim')
local humanoid = script.Parent.Parent:WaitForChild('Zombie')
local walkani = humanoid:LoadAnimation(animation1)
local animation2 = script.Parent.Parent.Animations:WaitForChild('Idle1')
local Idleani = humanoid:LoadAnimation(animation2)
local animationalreadyplaying = false
local canplayanimation = false


local humanoid = script.Parent
local root = humanoid.Parent.PrimaryPart

local targetDistance = 20
local stopDistance = 0

function findNearestPlayer()
	local playerList = Players:GetPlayers()
	
	local nearestPlayer = nil
	local distance = nil
	local direction = nil
	
	for _, player in pairs(playerList) do
		local character = player.Character
		if character then
			local distanceVector = (player.Character.HumanoidRootPart.Position - root.Position)
			if not nearestPlayer then
				nearestPlayer = player
				distance = distanceVector.Magnitude
				direction = distanceVector.Unit
			elseif distanceVector.Magnitude < distance then
				nearestPlayer = player
				distance = distanceVector.Magnitude
				direction = distanceVector.Unit
			end	
		end
	end
	
	return nearestPlayer, distance, direction
end

function Stopanimation()
	local nearestPlayer, distance, direction = findNearestPlayer()
	if nearestPlayer then
		if distance > targetDistance then
			walkani:Stop()
			animationalreadyplaying = false
			Idleani:Play()
			canplayanimation = false
		else
			Idleani:Stop()
			canplayanimation = true
		end
	
	end
  
end

RunService.Heartbeat:Connect(function()
	local nearestPlayer, distance, direction = findNearestPlayer()
	if nearestPlayer then
		if distance <= targetDistance and distance >= stopDistance then
			
			if animationalreadyplaying == false and canplayanimation then
				walkani:Play()
				animationalreadyplaying = true
			end
			humanoid:Move(direction)
			
		else
			if animationalreadyplaying == false and canplayanimation then
				walkani:Play()
				animationalreadyplaying = true
			end
			humanoid:Move(Vector3.new())
		end
	end
end)



while true do
	Stopanimation()
	wait(0.5)
end

