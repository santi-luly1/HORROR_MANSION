local require = require(script.Parent.loader).load(script)

local GameFunctions = {}
GameFunctions.ServiceName = "GameFunctions"

local _serviceBag
local Settings
local KillersController
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function GameFunctions:Init(serviceBag)
    _serviceBag = assert(serviceBag, "No serviceBag provided")
    Settings = _serviceBag:GetService(require("GameSettings")).Main

    local ok, kc = pcall(function()
        return _serviceBag:GetService(require("KillersController"))
    end)
    if ok then
        KillersController = kc
    end
end

-- DataCreator/DataDestroyer responsibilities moved to `DataStores`.
function GameFunctions.DataCreator(_plr)
    -- No-op: DataStores handles leaderstats and persistent player data.
end

function GameFunctions.DataDestroyer(_plr)
    -- No-op: DataStores handles cleanup on player removal.
end

function GameFunctions.chooseRandomSpawn(killer)
    if not killer then return end
    local map = Settings.Map
    if not map or not map:FindFirstChild("Map") then return end
    local spawnsFolder = map.Map:FindFirstChild("Spawns")
    if not spawnsFolder or not spawnsFolder:FindFirstChild("Killers") then return end
    local Spawns = spawnsFolder.Killers:GetChildren()
    if #Spawns == 0 then return end
    local Selected = math.random(1, #Spawns)
    local tp_CFrame = Spawns[Selected].CFrame
    local TeleportPart = killer:FindFirstChild("HumanoidRootPart") or killer:FindFirstChild("Torso") or killer:FindFirstChild("UpperTorso") or killer:FindFirstChild("Head")
    if TeleportPart then
        TeleportPart.CFrame = tp_CFrame
    end
end

function GameFunctions.chooseRandomKiller()
    if KillersController and type(KillersController.SpawnRandomKiller) == "function" then
        local ok, clone = pcall(function()
            return KillersController:SpawnRandomKiller()
        end)
        if ok then
            if clone then
                Settings.Killer = clone
            end
            return clone
        end
    end
    return nil
end

function GameFunctions.startGame()
    -- Lightweight orchestrator: spawn killer and notify clients via RemoteEvent if available.
    local killer = GameFunctions.chooseRandomKiller()
    if killer and ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("SendChatMessages") then
        pcall(function()
            ReplicatedStorage.RemoteEvents.SendChatMessages:FireAllClients(killer.Name)
        end)
    end
end

function GameFunctions.endGame()
    -- Lightweight end: clear active killers via KillersController and notify clients.
    if KillersController and type(KillersController.Clear) == "function" then
        pcall(function()
            KillersController:Clear()
        end)
    end
    if ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEnded") then
        pcall(function()
            ReplicatedStorage.RemoteEvents.GameEnded:FireAllClients()
        end)
    end
end

return GameFunctions
