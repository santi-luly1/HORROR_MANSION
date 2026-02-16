--!strict
local Services = game:GetService("ServerScriptService").Server

local KillerController = require(Services.KillerController)

return function(context, name: string)
	local currentKillers = KillerController:GetCurrentKillers()
	if #currentKillers == 0 then
		context:Reply(`No killers found.`, Color3.fromRGB(255, 200, 0))
		return ""
	end
	if not KillerController:IsValidName(name) and (name ~= "*" and name ~= "**") then
		context:Reply(`Invalid name.`, Color3.fromRGB(255, 0, 0))
		return ""
	end

	if name == "*" then
		for _, killer in ipairs(currentKillers) do
			local humanoid = killer:FindFirstChild("Humanoid") :: Humanoid
			humanoid.Health = 0
			context:Reply(`{killer.Name} was killed.`, Color3.fromRGB(0, 255, 0))
		end
	elseif name == "**" then
		local selectedKiller = currentKillers[math.random(1, #currentKillers)]
		local humanoid = selectedKiller:FindFirstChild("Humanoid") :: Humanoid
		humanoid.Health = 0
		context:Reply(`{selectedKiller.Name} was killed.`, Color3.fromRGB(0, 255, 0))
	else
		local targetKiller = nil
		for _, killer in ipairs(currentKillers) do
			if killer.Name == name then
				targetKiller = killer
				break
			end
		end

		if not targetKiller then
			context:Reply(`{name} was not found in round.`, Color3.fromRGB(255, 0, 0))
			return ""
		end

		local humanoid = targetKiller:FindFirstChild("Humanoid") :: Humanoid
		humanoid.Health = 0
		context:Reply(`{name} was killed.`, Color3.fromRGB(0, 255, 0))
	end

	return ""
end
