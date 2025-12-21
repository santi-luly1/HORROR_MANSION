function findNearestTorso(pos)
	local list = game.Workspace:children()
	local torso = nil
	local dist = 10000
	local temp = nil
	local human = nil
	local temp2 = nil

	for x = 1, #list do
		temp2 = list[x]
		if (temp2.className == "Model") and (temp2 ~= script.Parent) then
			temp = temp2:findFirstChild("HumanoidRootPart")
			human = temp2:findFirstChild("Humanoid")
			if (temp ~= nil) and (human ~= nil) and (human.Health > 0) then
				if (temp.Position - pos).magnitude < dist then
					torso = temp
					dist = (temp.Position - pos).magnitude
				end
			end
		end
	end

	if torso ~= nil then
		return torso
	end
end

while true do
	local s, mainErrorMessage = pcall(function()
		wait(1)
		local humanoid = nil

		for _, hum in pairs(script.Parent:GetDescendants()) do
			if hum:IsA'Humanoid' then
				humanoid = hum
			end
		end
		if humanoid == nil then return end
		for _, parts in pairs(humanoid.Parent:GetChildren()) do
			if parts:IsA'Part' --[[and parts.Name == "HumanoidRootPart" or parts.Name == "Torso" or parts.Name == "Head"]] then
				parts.Touched:Connect(function(h)
					if h.Parent:FindFirstChild'Humanoid' then
						h.Parent.Humanoid.Health = 0
					end
				end)
			end
		end

		local path = game:GetService("PathfindingService"):CreatePath()
		local destination = findNearestTorso(humanoid.Parent.Head.Position)
		local torso = humanoid.Parent:FindFirstChild("Torso")

		if torso == nil then
			torso = humanoid.Parent:FindFirstChild("HumanoidRootPart")
			if torso == nil then
				torso = humanoid.Parent:FindFirstChild("Head")
				if torso == nil then
					torso = humanoid.Parent:FindFirstChild("UpperTorso")
				end
			end
		end

		local s, errorMessage = pcall(function()
			if torso ~= nil and destination ~= nil then
				path:ComputeAsync(torso.Position, destination.Position)
			end
		end)

		if not s then
			warn("Error in the "..humanoid.Parent.Name.." model: \n", errorMessage)
		end

		local waypoints = path:GetWaypoints()

		for i, waypoint in pairs(waypoints) do
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end

			humanoid:MoveTo(waypoint.Position)
			humanoid.MoveToFinished:Wait()
		end
	end)

	if not s then warn("Error in the general enemy script: \n", mainErrorMessage) end
end
