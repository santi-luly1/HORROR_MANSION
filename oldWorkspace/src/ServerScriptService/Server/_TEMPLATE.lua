local _TEMPLATE = {}
_TEMPLATE.__index = _TEMPLATE

function _TEMPLATE.new(PRINT_UTILITY)
	local START_TICK = tick()
	local self = setmetatable({
		_PrintUtility = PRINT_UTILITY;
	}, _TEMPLATE)
	
	
	self._PrintUtility:PrintScriptLoaded(script, START_TICK)
	return self
end

return _TEMPLATE
