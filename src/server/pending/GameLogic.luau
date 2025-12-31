local require = (require :: any)(script.Parent.loader).load(script)

local GameLogic = {}
GameLogic.ServiceName = "GameLogic"

local _serviceBag
local Settings
local functionsTable

local function ensureFlagTable()
    Settings["ServerScriptService.GameLogic"] = Settings["ServerScriptService.GameLogic"] or {}
    return Settings["ServerScriptService.GameLogic"]
end

function GameLogic:Init(serviceBag)
    _serviceBag = serviceBag
    Settings = _serviceBag:GetService(require("GameSettings")).Main
    functionsTable = _serviceBag:GetService(require("GameFunctions"))
end

function GameLogic:Start()
    task.spawn(function()
        while true do
            task.wait(1)
            if #workspace.MessagesHints:GetChildren() > 50 then
                workspace.MessagesHints:ClearAllChildren()
            end
            print("Game Timer:", Settings.GameTimer.Countdown)
            if Settings.GameTimer.Countdown > 0 then
                print("Decreasing countdown:", Settings.GameTimer.Countdown)
                Settings.GameTimer.Countdown = Settings.GameTimer.Countdown - 1
                workspace.MessagesHints.Timer.Text = Settings.Killer.Name .. " will leave in " .. Settings.GameTimer.Countdown .. " seconds."

                local flags = ensureFlagTable()
                if not flags.EndGame_db then
                    functionsTable.endGame()
                    flags.EndGame_db = true
                end
            elseif Settings.GameTimer.Countdown <= 0 then
                print  ("Countdown reached zero, ending game.")
                functionsTable.endGame()
            end
        end
    end)
end

return GameLogic
