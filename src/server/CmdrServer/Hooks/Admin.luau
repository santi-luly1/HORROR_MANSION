---!strict
local CmdrConfig = require("@src/shared/CmdrConfig")

local group = script.Name

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		if context.Group == group and table.find(CmdrConfig.Permissions[group], context.Executor.UserId) == nil then
			return "Not authorized."
		end

		return
	end)
end
