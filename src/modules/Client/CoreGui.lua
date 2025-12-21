local CoreGui = {}
CoreGui.ServiceName = "CoreGui"
CoreGui.__index = CoreGui

function CoreGui:Init(_serviceBag)
    -- no-op; kept for ServiceBag compatibility
end

function CoreGui.new(starterGui, _PRINT_UTILITY)
    local START_TICK = tick()
    local self = setmetatable({
        _StarterGui = starterGui,
        _PrintUtility = _PRINT_UTILITY,
    }, CoreGui)

    self:SetDefaults()
    if self._PrintUtility and type(self._PrintUtility.PrintScriptLoaded) == "function" then
        self._PrintUtility:PrintScriptLoaded(script, START_TICK)
    end
    return self
end

function CoreGui:SetDefaults()
    -- placeholder for core GUI settings
end

function CoreGui:SetCore(key, value)
    local function exe()
        self._StarterGui:SetCore(key, value)
    end

    local function Status()
        local Success, Result = pcall(exe)
        return { Success = Success, Result = Result }
    end

    if not Status().Success then
        repeat
            task.wait()
            Status()
        until Status().Success
    end
end

function CoreGui:SetCoreGuiEnabled(key, value)
    local function exe()
        self._StarterGui:SetCoreGuiEnabled(key, value)
    end

    local function Status()
        local Success, Result = pcall(exe)
        return { Success = Success, Result = Result }
    end

    if not Status().Success then
        repeat
            task.wait()
            Status()
        until Status().Success
    end
end

return CoreGui
