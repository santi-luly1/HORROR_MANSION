local functions = require(game.ReplicatedStorage.Modules.GameFunctions)

game.Players.PlayerAdded:Connect(function(p)
	functions.DataCreator(p)
end)
game.Players.PlayerRemoving:Connect(function(p)
	functions.DataDestroyer(p)
end)