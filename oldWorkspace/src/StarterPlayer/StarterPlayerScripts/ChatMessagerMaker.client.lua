game.ReplicatedStorage.RemoteEvents.SendChatMessages.OnClientEvent:Connect(function(killerName)
	game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
		Text = killerName.." Arrived!",
		Color = Color3.fromRGB(255, 52, 17),
		Font = Enum.Font.Code,
		TextSize = 20})
end)