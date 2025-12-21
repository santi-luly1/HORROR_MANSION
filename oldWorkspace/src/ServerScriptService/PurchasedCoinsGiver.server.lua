game.ReplicatedStorage.RemoteEvents.GiveCoins.OnServerEvent:Connect(function(player, toGive)
	warn("[Purchaasing Coins] Gived ", tonumber(toGive), " to ", player.Name, " successfully.")
	player.leaderstats.Coins.Value += tonumber(toGive)
end)