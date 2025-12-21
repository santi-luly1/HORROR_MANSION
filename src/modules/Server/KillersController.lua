local KillersController = {}
KillersController.ServiceName = "KillersController"

local require = require(script.Parent.loader).load(script)

function KillersController:Init(serviceBag)
    assert(not self._serviceBag, "Already initialized")
    self._serviceBag = assert(serviceBag, "No serviceBag provided")

    self._serverStorage = game:GetService("ServerStorage")
    self._replicatedStorage = game:GetService("ReplicatedStorage")
    self._workspace = game:GetService("Workspace")
    self._script = script
end

local KillerAI
local function lazyLoadAI(self)
    if not KillerAI then
        -- Prefer a service-registered KillerAI when available
        if self._serviceBag then
            local ok, svc = pcall(function()
                return self._serviceBag:GetService(require("KillerAI"))
            end)
            if ok and svc then
                KillerAI = svc
            end
        end

        -- Fallback to ReplicatedStorage module for compatibility
        if not KillerAI then
            local ok, mod = pcall(function()
                return require(self._replicatedStorage:WaitForChild("Modules"):WaitForChild("KillerAI"))
            end)
            if ok then
                KillerAI = mod
            end
        end
    end
    return KillerAI
end

local function clearWorkspaceKillers(workspaceRef)
    if workspaceRef:FindFirstChild("Killer") then
        for _, v in ipairs(workspaceRef.Killer:GetChildren()) do
            if v:IsA("Model") then
                v:Destroy()
            end
        end
    end
end

function KillersController:SpawnKillerByName(name)
    local killersFolder = self._serverStorage:FindFirstChild("Killers")
    if not killersFolder then return nil, "No Killers folder" end

    local candidate = killersFolder:FindFirstChild(name)
    if not candidate then return nil, "Killer not found" end

    if not self._workspace:FindFirstChild("Killer") then
        local killerFolder = Instance.new("Folder")
        killerFolder.Name = "Killer"
        killerFolder.Parent = self._workspace
    end
    clearWorkspaceKillers(self._workspace)

    local clone = candidate:Clone()
    clone.Parent = self._workspace.Killer

    local ai = lazyLoadAI(self)
    if ai and type(ai.Start) == "function" then
        pcall(function()
            ai.Start(clone)
        end)
    end

    local initMod = clone:FindFirstChild("Init") or clone:FindFirstChild("Controller")
    if initMod and initMod:IsA("ModuleScript") then
        pcall(function()
            local ok, m = pcall(require, initMod)
            if ok and type(m.Init) == "function" then
                m.Init(clone)
            elseif ok and type(m.Start) == "function" then
                m.Start(clone)
            end
        end)
    end

    return clone
end

function KillersController:SpawnRandomKiller()
    local killersFolder = self._serverStorage:FindFirstChild("Killers")
    if not killersFolder then return nil, "No Killers folder" end

    local list = killersFolder:GetChildren()
    if #list == 0 then return nil, "No killers available" end

    local selected = list[math.random(1, #list)]
    return self:SpawnKillerByName(selected.Name)
end

function KillersController:Clear()
    clearWorkspaceKillers(self._workspace)
end

function KillersController:GetActive()
    if self._workspace:FindFirstChild("Killer") then
        for _, v in ipairs(self._workspace.Killer:GetChildren()) do
            if v:IsA("Model") then
                return v
            end
        end
    end
    return nil
end

return KillersController
