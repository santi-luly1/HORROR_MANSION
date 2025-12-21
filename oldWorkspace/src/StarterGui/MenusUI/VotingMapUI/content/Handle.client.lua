game:GetService("UserInputService").InputBegan:Connect(function(key, gpe)
	game.ReplicatedStorage.RemoteEvents.KeyPressed:FireServer(key.KeyCode, gpe)
end)