local MainFigure = script.Parent
local CONFIG = {
	Damage = 100;
	Distance = 1000;
	OnlyKillPlayers = true;
}

local function FindTorso(pos)
	local list = workspace:GetChildren()
	local torso = nil
	
	for Parts = 1, #list do
		local Part = list[Parts]
		
		if Part:IsA'Model' and Part ~= MainFigure then
			if Part:FindFirstChild("HumanoidRootPart") and Part:FindFirstChild("Humanoid") then
				if (Part.HumanoidRootPart.Position - pos).Magnitude < CONFIG.Distance then
					torso = Part
				end
			end
		end
	end

	return torso
end

while true do
	local s, mainErrorMessage = pcall(function()
		wait(1)
		local Humanoid = MainFigure:FindFirstChild("Humanoid", true)

		if Humanoid then
			local path = game:GetService("PathfindingService"):CreatePath()
			local destination = FindTorso(Humanoid.Parent.Head.Position)
			local torso = MainFigure:FindFirstChild("Torso")
			
			-- // Find a torso
			if torso == nil then
				torso = Humanoid.Parent:FindFirstChild("HumanoidRootPart")
				
				if torso == nil then
					torso = Humanoid.Parent:FindFirstChild("Head")
					
					if torso == nil then
						torso = Humanoid.Parent:FindFirstChild("UpperTorso")
					end
				end
			end
			
			
			local succ, errorMessage = pcall(function()
				if torso and destination then
					path:ComputeAsync(torso.Position, destination.Position)
				end
			end)

			if succ then
				for _, waypoint in pairs(path:GetWaypoints()) do
					if waypoint.Action == Enum.PathWaypointAction.Jump then
						Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end

					Humanoid:MoveTo(waypoint.Position)
					Humanoid.MoveToFinished:Wait()
				end
			else
				warn(string.format("Error in the %s model: \n %s", MainFigure.Name, errorMessage))
			end
			
			-- // Kill the player on touch
			for _, parts in pairs(MainFigure:GetChildren()) do
				if parts:IsA'Part' and parts.Name == ("HumanoidRootPart" or "Torso" or "Head") then
					parts.Touched:Connect(function(h)
						if h.Parent:FindFirstChild'Humanoid' then
							if CONFIG.OnlyKillPlayers then
								if game.Players:FindFirstChild(h.Parent.Name) then
									h.Parent.Humanoid.Health -= CONFIG.Damage
								end
							else
								h.Parent.Humanoid.Health -= CONFIG.Damage
							end
						end
					end)
				end
			end
		end
	end)

	if not s then
		warn("Error in the general enemy script: \n", mainErrorMessage)
	end
end
