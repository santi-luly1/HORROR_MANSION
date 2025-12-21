local CoreGui = {}
CoreGui.__index = CoreGui

function CoreGui.new(StarterGui: StarterGui, PRINT_UTILITY)
	local START_TICK = tick()
	local self = setmetatable({
		_StarterGui = StarterGui;
		_PrintUtility = PRINT_UTILITY;
	}, CoreGui)
	
	self:SetDefaults()
	
	self._PrintUtility:PrintScriptLoaded(script, START_TICK)
	return self
end

function CoreGui:SetDefaults()
	--[[
	self:SetCore('BadgesNotificationsActive', false)
	self:SetCore('ResetButtonCallback', false)
	self:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	self:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	--]]
end

function CoreGui:SetCore(Key: string, Value: boolean)
	local function exe()
		self._StarterGui:SetCore(Key, Value)
	end
	
	local function Status()
		local Success, Result = pcall(exe)
		
		return {
			Success = Success;
			Result = Result
		}
	end
	
	
	if not Status().Success then
		repeat
			task.wait()
			Status()
		until Status().Success
	end
end

function CoreGui:SetCoreGuiEnabled(Key: Enum.CoreGuiType, Value: boolean)
	local function exe()
		self._StarterGui:SetCoreGuiEnabled(Key, Value)
	end

	local function Status()
		local Success, Result = pcall(exe)

		return {
			Success = Success;
			Result = Result
		}
	end


	if not Status().Success then
		repeat
			task.wait()
			Status()
		until Status().Success
	end
end


return CoreGui