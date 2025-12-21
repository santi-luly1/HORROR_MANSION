local Creators = {
	605354831;
	1270367002;
}

game:GetService("UserInputService").InputBegan:Connect(function(key, gpe)
	if not table.find(Creators, game.Players.LocalPlayer.UserId) then
		script.Parent.Parent.Parent.ResetOnSpawn = true
	else
		script.Parent.Parent.Parent.ResetOnSpawn = false
	end
	
	if gpe then return end
	
	if key.KeyCode == Enum.KeyCode.L then
		if table.find(Creators, game.Players.LocalPlayer.UserId) then
			script.Parent.Parent.Parent.Enabled = not script.Parent.Parent.Parent.Enabled
		end
	end
end)