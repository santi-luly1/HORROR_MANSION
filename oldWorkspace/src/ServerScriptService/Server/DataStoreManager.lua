local DataStoreManager = {}
DataStoreManager.__index = DataStoreManager

function DataStoreManager.new(Players: Players, DataStoreService: DataStoreService, PRINT_UTILITY)
	local START_TICK = tick()
	local self = setmetatable({
		_Players = Players;
		_DataStoreService = DataStoreService;
		_PrintUtility = PRINT_UTILITY;
	}, DataStoreManager)
	
	
	
	
	
	self._PrintUtility:PrintScriptLoaded(script, START_TICK)
	return self
end

return DataStoreManager
