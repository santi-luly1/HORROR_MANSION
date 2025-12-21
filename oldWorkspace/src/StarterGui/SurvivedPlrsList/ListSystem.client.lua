local function Update()
	for _, guis in pairs(script.Parent.Content:GetChildren()) do
		if guis:IsA'Frame' then
			guis:Destroy()
		end
	end
	
	for _, survivedPlayers in pairs(game.ReplicatedStorage.SavedPlayers.SurvivedPlayers:GetChildren()) do
		local ClonedFrame = script.PlayerFrame:Clone()
		
		ClonedFrame.Name = survivedPlayers.Name
		ClonedFrame.PlayerName.Text = survivedPlayers.Name
		ClonedFrame.PlayerFaceImage.Image = game.Players:GetUserThumbnailAsync(game.Players:GetUserIdFromNameAsync(survivedPlayers.Name), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		ClonedFrame.Parent = script.Parent.Content
	end
end

game.ReplicatedStorage.SavedPlayers.SurvivedPlayers.ChildAdded:Connect(Update)
game.ReplicatedStorage.SavedPlayers.SurvivedPlayers.ChildRemoved:Connect(Update)