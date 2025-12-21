local Assign = {}
Assign.ServiceName = "Assign"

function Assign:Init(serviceBag)
    assert(not self._serviceBag, "Already initialized")
    self._serviceBag = assert(serviceBag, "No serviceBag provided")
    self._replicatedStorage = game:GetService("ReplicatedStorage")
end

function Assign:Start()
    local success, err = pcall(function()
        local evt = self._replicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DiedEvent")
        evt.OnServerEvent:Connect(function(plr, parent)
            warn("Received, moving ", plr.Name, ">", parent:GetFullName())
            local saved = self._replicatedStorage:FindFirstChild("SavedPlayers")
            if saved and saved:FindFirstChild("SurvivedPlayers") and saved.SurvivedPlayers:FindFirstChild(plr.Name) then
                saved.SurvivedPlayers[plr.Name].Parent = parent
            end
        end)
    end)

    if not success then
        warn("Assign: failed to bind DiedEvent", err)
    end
end

return Assign
