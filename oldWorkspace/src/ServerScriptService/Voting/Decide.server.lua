local YesVotes = script.Parent.YesVotes
local NoVotes = YesVotes.Parent.NoVotes
local TotalMaps = NoVotes.Parent.TotalAvailableMaps

local db = false

local function chooseRandomMap()
	local Maps = game.ServerStorage.Maps:GetChildren()
	local SelectMap = math.random(1, #Maps)
	local SelectedMap = Maps[SelectMap]
	
	if SelectedMap.IsAvailable.Value then
		warn("[Changing Map] ", SelectedMap.Name .." ("..SelectedMap:GetFullName()..") was selected.")
		
		workspace.HouseFolder:ClearAllChildren()
		
		local mapClone = SelectedMap:Clone()
		mapClone.Parent = workspace.HouseFolder
	else
		warn("[Changing Map]", SelectedMap.Name," (", SelectedMap:GetFullName(), ")", " was selected. But", SelectedMap.Name, " is currently disabled or not available.")
		chooseRandomMap()
	end
	
	task.wait()
end

while game["Run Service"].Heartbeat:Wait() do
	if workspace.MessagesHints:FindFirstChild("EndedWaitCountdown") then
		if workspace.MessagesHints.EndedWaitCountdown.Text == "The next killer will spawn in 0 seconds." and not db then
			db = true
			if YesVotes.Value > NoVotes.Value then
				warn("[Changing Map] 'Yes' was the winner, changing map")
				chooseRandomMap()
			elseif YesVotes.Value == NoVotes.Value then
				local Selectrandom = math.random(1, 2)
				if Selectrandom == 1 then
					chooseRandomMap()
				end
			else
				warn("[Changing Map] 'No' was the winner or it was a tie, map is not gonna change.")
			end
			
			YesVotes.Value = 0
			NoVotes.Value = 0
			TotalMaps.Value = 0

			wait(2.5)
			db = false
		end
	end
end
