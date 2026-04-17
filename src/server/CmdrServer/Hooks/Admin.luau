---!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrConfig = require(ReplicatedStorage.Shared.CmdrConfig)

local group = script.Name

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		if context.Group == group and table.find(CmdrConfig.Permissions[group], context.Executor.UserId) == nil then
			return "Not authorized."
		end

		return
	end)
end
