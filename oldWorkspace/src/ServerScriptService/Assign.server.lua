game.ReplicatedStorage.RemoteEvents.DiedEvent.OnServerEvent:Connect(function(plr, parent)
	warn("Recived, moving "..plr.Name.." > "..parent:GetFullName()..".")
	game.ReplicatedStorage.SavedPlayers.SurvivedPlayers[plr.Name].Parent = parent
end)
