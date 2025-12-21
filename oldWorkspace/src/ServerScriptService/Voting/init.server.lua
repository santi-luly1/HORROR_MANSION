--// Voting
local YesVotes = 0
local NoVotes = 0

--// Available Maps
local TotalAvailableMaps = script.TotalAvailableMaps

--// Player to find
local Playerr = nil

--// Keys
local VoteYesKey = Enum.KeyCode.Q
local VoteNoKey = Enum.KeyCode.E

--// Bools
local CountMaps = true

--// Main
while wait() do
	game.ReplicatedStorage.RemoteEvents.KeyPressed.OnServerEvent:Connect(function(Player, key, gpe)
		local confirmationsFolder = Player:FindFirstChild("Confirmations")
		local Gui = Player.PlayerGui:WaitForChild("MenusUI", 30).VotingMapUI
		
		Playerr = Player
		
		if gpe or not Gui.Enabled then return end
		
		if not confirmationsFolder then
			local folder = Instance.new("Folder", Player)
			folder.Name = "Confirmations"
			confirmationsFolder = folder
		end
		
		if key == VoteYesKey and not confirmationsFolder:FindFirstChild("Voted") then
			YesVotes += 1
			script.YesVotes.Value += 1
			game.ReplicatedStorage.RemoteEvents.KeyPressed.ChangeVotingColor:FireClient(Player, Gui.content.Yes, Gui.content.No)
			
			local VotedConfirmation = Instance.new("BoolValue", confirmationsFolder)
			VotedConfirmation.Name = "Voted"
			VotedConfirmation.Value = true
		elseif key == VoteNoKey and not confirmationsFolder:FindFirstChild("Voted") then
			NoVotes += 1
			script.NoVotes.Value += 1
			game.ReplicatedStorage.RemoteEvents.KeyPressed.ChangeVotingColor:FireClient(Player, Gui.content.No, Gui.content.Yes)
			
			local VotedConfirmation = Instance.new("BoolValue", confirmationsFolder)
			VotedConfirmation.Name = "Voted"
			VotedConfirmation.Value = true
		end
		
		if CountMaps then
			CountMaps = false
			for _, maps in pairs(game.ServerStorage.Maps:GetChildren()) do
				local AvailableValue = maps:WaitForChild'IsAvailable'

				if AvailableValue.Value then
					TotalAvailableMaps.Value += 1
				end
			end
		end
		
		
		Gui.content.Title.Text = "Change Map? ("..TotalAvailableMaps.Value.." maps available)"
		Gui.content.Yes.Votes.Text = "Votes: "..script.YesVotes.Value
		Gui.content.No.Votes.Text = "Votes: "..script.NoVotes.Value
		Gui.content.TotalVotes.Text = "Total Votes: "..(script.YesVotes.Value + script.NoVotes.Value)
	end)
	
	if workspace.MessagesHints:FindFirstChild("EndedWaitCountdown") then
		if workspace.MessagesHints.EndedWaitCountdown.Text == "The next killer will spawn in 0 seconds." and Playerr ~= nil then
			wait(.2)
			CountMaps = true
			
			if Playerr ~= nil then
				if Playerr:FindFirstChild("Confirmations") and Playerr:FindFirstChild("Confirmations"):FindFirstChild("Voted") then
					Playerr.Confirmations.Voted:Destroy()
				end
			end
		end
	end
end
