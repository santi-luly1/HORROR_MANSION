local ServerStorage = game:GetService("ServerStorage")

local Settings = {
    Main = {
        GameTimer = { Countdown = 120, Base = 120, Default = 120, ["In-game_error"] = 10 },
        Killer = nil,
        Map = ServerStorage:WaitForChild("Maps"):WaitForChild("StandardHouse"),
        ["ServerScriptService.GameLogic"] = {
            Voting = { TotalStartedMatchs = 0, Min = 3 },
            waitTimes = 3.25,
            IntermissionTime = 10,
            minChildrensInFolder = 3,
            EndGame_db = false,
            DoStartGame = true,
            showChangeMap = true,
        },
    }
}

function Settings:SetTextTitle(_)
    -- server-side placeholder for logging or future localization hooks
end

return Settings
