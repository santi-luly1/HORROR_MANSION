game.ReplicatedStorage.RemoteEvents.KeyPressed.ChangeVotingColor.OnClientEvent:Connect(function(green, neutral)
	green.TextColor3 = Color3.fromRGB(0, 255)
	neutral.TextColor3 = Color3.fromRGB(255, 255, 255)
end)