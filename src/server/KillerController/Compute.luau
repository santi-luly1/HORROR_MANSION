--!strict
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local function findNearestTorso(pos: Vector3): Part?
	local closest, dist = nil, math.huge

	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: Part
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and not char:FindFirstChildOfClass("ForceField") then
			local d = (hrp.Position - pos).Magnitude
			if d < dist then
				closest, dist = hrp, d
			end
		end
	end

	return closest
end

return function(model: Model, maid: any, customPosition: Vector3?): boolean
	local humanoid = model:FindFirstChild("Humanoid") :: Humanoid
	local torso = model:FindFirstChild("HumanoidRootPart") :: Part
	if not humanoid or not torso then
		warn(`{model:GetFullName()} has no humanoid or HRP`)
		return false
	end

	local target = findNearestTorso(torso.Position)
	if not target then
		warn(`{model:GetFullName()} has not found any HRP`)
		return false
	end

	local path = PathfindingService:CreatePath({
		AgentHeight = 5,
		AgentRadius = 2,
		AgentCanJump = true,
	})
	path:ComputeAsync(torso.Position, target.Position)
	if path.Status ~= Enum.PathStatus.Success then
		return false
	end

	local lastTargetPos = target.Position -- snapshot
	local waypoints = path:GetWaypoints()

	for i, waypoint in ipairs(waypoints) do
		if not model.Parent or humanoid.Health <= 0 then
			break
		end

		if (target.Position - lastTargetPos).Magnitude >= 10 and i / #waypoints <= 0.75 then -- if the target got 10 studs away from the destination, and the progress made is below 75%, then recalculate
			warn(`{target.Parent} moved 10 studs away from original destination, break.`)
			break
		end

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		humanoid:MoveTo(waypoint.Position)
		local moved = humanoid.MoveToFinished:Wait()
		if not moved then
			break
		end
	end
	return true
end
