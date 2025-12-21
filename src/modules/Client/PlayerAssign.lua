local PlayerAssign = {}
PlayerAssign.ServiceName = "PlayerAssign"

local ReplicatedStorage

function PlayerAssign:Init(serviceBag)
    self._serviceBag = serviceBag
    ReplicatedStorage = game:GetService("ReplicatedStorage")
end

function PlayerAssign.OnCharacter(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end

    humanoid.Died:Connect(function()
        local name = character.Name
        local saved = ReplicatedStorage:FindFirstChild("SavedPlayers")
        if not saved then
            return
        end
        if not saved.NeutralPlayers:FindFirstChild(name) then
            if saved.SurvivedPlayers:FindFirstChild(name) then
                pcall(function()
                    ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DiedEvent"):FireServer(saved.DiedPlayers)
                end)
            end
        end
    end)
end

return PlayerAssign
