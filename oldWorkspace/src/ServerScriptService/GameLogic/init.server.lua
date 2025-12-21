local functionsTable = require(game.ReplicatedStorage.Modules.GameFunctions)
local Settings = require(game.ReplicatedStorage.Modules.GameSettings).Main

while wait(1) do
	if #workspace.MessagesHints:GetChildren() > 50 then workspace.MessagesHints:ClearAllChildren() end
	
	if Settings.GameTimer.Countdown > 0 then
		Settings.GameTimer.Countdown -= 1
		
		local s, errorMessage = pcall(function()
			workspace.MessagesHints.Timer.Text = Settings.Killer.Name.." will leave in "..Settings.GameTimer.Countdown.." seconds."
		end)
		
		if not Settings["ServerScriptService.GameLogic"].EndGame_db then
			functionsTable.endGame()
			Settings["ServerScriptService.GameLogic"].EndGame_db = true
		end
	elseif Settings.GameTimer.Countdown <= 0 then
		functionsTable.endGame()
	end
end
