local SurvivedList = {}
SurvivedList.ServiceName = "SurvivedList"

local ReplicatedStorage
local Players

function SurvivedList:Init(serviceBag)
    self._serviceBag = serviceBag
    ReplicatedStorage = game:GetService("ReplicatedStorage")
    Players = game:GetService("Players")
end

local function populate(container, template)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local saved = ReplicatedStorage:WaitForChild("SavedPlayers"):WaitForChild("SurvivedPlayers")
    for _, survived in ipairs(saved:GetChildren()) do
        if survived:IsA("IntValue") then
            local cloned = template:Clone()
            cloned.Name = survived.Name
            cloned.PlayerName.Text = survived.Name
            local ok, userId = pcall(function()
                return Players:GetUserIdFromNameAsync(survived.Name)
            end)
            if ok and userId then
                local thumb = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                cloned.PlayerFaceImage.Image = thumb
            end
            cloned.Parent = container
        end
    end
end

function SurvivedList.Start(container, template)
    local saved = ReplicatedStorage:WaitForChild("SavedPlayers"):WaitForChild("SurvivedPlayers")

    local function Update()
        pcall(function()
            populate(container, template)
        end)
    end

    saved.ChildAdded:Connect(Update)
    saved.ChildRemoved:Connect(Update)

    -- initial population
    Update()
end

return SurvivedList
