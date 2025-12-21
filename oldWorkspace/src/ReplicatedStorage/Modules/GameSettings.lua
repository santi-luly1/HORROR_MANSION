local Settings = {
	CreatorPanel = {Day = false};
	Main = {
		GameTimer = {Countdown = 120; Base = 120; Default = 120; ["In-game_error"] = 10};
		Killer = nil;
		Map = game.ServerStorage.Maps.StandardHouse;
		["ServerScriptService.GameLogic"] = {
			Voting = {
				TotalStartedMatchs = 0;
				Min = 3;
			};
			waitTimes = 3.25;
			IntermissionTime = 10;
			minChildrensInFolder = 3;
			EndGame_db = false;
			DoStartGame = true;
			showChangeMap = true;
		};
	}
}

function Settings:SetTextTitle(text)
	
end

return Settings