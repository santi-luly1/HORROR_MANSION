local RFP = {}
RFP.ServiceName = "RFP"

local RunService
local workspaceRef
local connections = {}

function RFP:Init(serviceBag)
    self._serviceBag = serviceBag
    RunService = game:GetService("RunService")
    workspaceRef = game:GetService("Workspace")
end

local function cleanup(character)
    if connections[character] then
        for _, c in ipairs(connections[character]) do
            if c then
                pcall(function()
                    c:Disconnect()
                end)
            end
        end
        connections[character] = nil
    end
end

function RFP.OnCharacter(character)
    cleanup(character)
    local conns = {}
    connections[character] = conns

    local humanoid = character:FindFirstChild("Humanoid")
    local torso = character:FindFirstChild("Torso")
    local head = character:FindFirstChild("Head")
    local rootpart = character:FindFirstChild("HumanoidRootPart")
    local rightShoulder = torso and torso:FindFirstChild("Right Shoulder")
    local leftShoulder = torso and torso:FindFirstChild("Left Shoulder")

    local camera = workspaceRef.CurrentCamera
    local updateSpeed = 0.25

    local renderConn = RunService.RenderStepped:Connect(function()
        if not (humanoid and torso and head and rootpart) then
            return
        end
        local rightArm = character:FindFirstChild("Right Arm")
        local leftArm = character:FindFirstChild("Left Arm")
        if rightArm then
            rightArm.LocalTransparencyModifier = rightArm.Transparency
        end
        if leftArm then
            leftArm.LocalTransparencyModifier = leftArm.Transparency
        end

        local camCF = camera and camera.CFrame
        if not camCF then
            return
        end
        local distance = (head.Position - camCF.p).Magnitude
        if distance <= 2 and humanoid.Health ~= 0 then
            if rightShoulder then
                rightShoulder.C0 = rightShoulder.C0:lerp((camCF * CFrame.new(1, -1, -.5)):ToObjectSpace(torso.CFrame):Inverse() * CFrame.Angles(0, math.pi/2, 0), updateSpeed)
            end
            if leftShoulder then
                leftShoulder.C0 = leftShoulder.C0:lerp((camCF * CFrame.new(-1, -1, -.5)):ToObjectSpace(torso.CFrame):Inverse() * CFrame.Angles(0, -math.pi/2, 0), updateSpeed)
            end
            if humanoid and rootpart and head then
                humanoid.CameraOffset = (rootpart.CFrame + Vector3.new(0,1.5,0)):PointToObjectSpace(head.CFrame.p)
            end
        else
            if rightShoulder then
                rightShoulder.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.pi/2, 0)
            end
            if leftShoulder then
                leftShoulder.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, -math.pi/2, 0)
            end
            if humanoid then
                humanoid.CameraOffset = Vector3.new(0,0,0)
            end
        end
    end)

    table.insert(conns, renderConn)

    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanup(character)
        end
    end)
end

return RFP
