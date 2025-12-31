local PathfindingService = game:GetService("PathfindingService")

local KillerAI = {}

local function findNearestTorso(pos)
    local list = workspace:GetChildren()
    local torso = nil
    local dist = math.huge

    for _, obj in ipairs(list) do
        if obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local human = obj:FindFirstChild("Humanoid")
            if hrp and human and human.Health > 0 then
                local d = (hrp.Position - pos).Magnitude
                if d < dist then
                    dist = d
                    torso = hrp
                end
            end
        end
    end

    return torso
end

local function setupTouchDamage(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                local hum = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
                if hum then
                    hum.Health = 0
                end
            end)
        end
    end
end

function KillerAI.Start(model)
    spawn(function()
        while model and model.Parent do
            local ok, err = pcall(function()
                local humanoid = nil
                for _, d in ipairs(model:GetDescendants()) do
                    if d:IsA("Humanoid") then
                        humanoid = d
                        break
                    end
                end
                if not humanoid then
                    return
                end

                setupTouchDamage(model)

                local torso = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso")
                local destination = findNearestTorso(humanoid.Parent.Head.Position)
                local path = PathfindingService:CreatePath()

                if torso and destination then
                    path:ComputeAsync(torso.Position, destination.Position)
                    local waypoints = path:GetWaypoints()
                    for _, waypoint in ipairs(waypoints) do
                        if waypoint.Action == Enum.PathWaypointAction.Jump then
                            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                        humanoid:MoveTo(waypoint.Position)
                        humanoid.MoveToFinished:Wait()
                    end
                end
            end)
            if not ok then
                warn("KillerAI error in model", model and model.Name, err)
            end
            wait(1)
        end
    end)
end

return KillerAI
