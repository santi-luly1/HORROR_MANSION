local require = require(script.Parent.loader).load(script)

local Adding = {}
Adding.ServiceName = "GameLogic.Adding"

local _serviceBag
local functions
local Players = game:GetService("Players")

function Adding:Init(serviceBag)
    _serviceBag = serviceBag
    functions = _serviceBag:GetService(require("GameFunctions"))
end

function Adding:Start()
    Players.PlayerAdded:Connect(function(p)
        pcall(function()
            functions.DataCreator(p)
        end)
    end)
    Players.PlayerRemoving:Connect(function(p)
        pcall(function()
            functions.DataDestroyer(p)
        end)
    end)
end

return Adding
