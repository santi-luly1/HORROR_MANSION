local PlayerVisuals = {}
PlayerVisuals.ServiceName = "PlayerVisuals"

local RunService
local connections = {}

function PlayerVisuals:Init(serviceBag)
    self._serviceBag = serviceBag
    RunService = game:GetService("RunService")
end

local function cleanup(character)
    local key = character
    if connections[key] then
        for _, c in ipairs(connections[key]) do
            if c then
                pcall(function()
                    c:Disconnect()
                end)
            end
        end
        connections[key] = nil
    end
end

function PlayerVisuals.OnCharacter(character)
    cleanup(character)
    local conns = {}
    connections[character] = conns

    local update = RunService.RenderStepped:Connect(function()
        for _, partName in ipairs({"Right Arm", "Left Arm", "Left Arm", "Right Arm"}) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.LocalTransparencyModifier = part.Transparency
            end
        end
    end)

    table.insert(conns, update)

    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanup(character)
        end
    end)
end

return PlayerVisuals
