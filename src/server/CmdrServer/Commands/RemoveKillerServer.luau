--!strict
local Services = game:GetService("ServerScriptService").Server

local KillerService = require(Services.KillerService)

return function(context, name: string) -- FIXME: this should skip the round, but it ends it instead.
	local currentKillers = KillerService:GetCurrentKillers()
	if #currentKillers == 0 then
		context:Reply(`No killers found.`, Color3.fromRGB(255, 200, 0))
		return ""
	end
	if not KillerService:IsValidName(name, true) then
		context:Reply(`Invalid name.`, Color3.fromRGB(255, 0, 0))
		return ""
	end

	if name == "*" then
		for _, killer in ipairs(currentKillers) do
			local humanoid = killer:FindFirstChild("Humanoid") :: Humanoid
			humanoid.Health = 0 -- would KillerService need its own "kill" killer API or would it be too fancy?
			context:Reply(`{killer.Name} was killed.`, Color3.fromRGB(0, 255, 0))
		end
	elseif name == "**" then
		local selectedKiller = currentKillers[math.random(1, #currentKillers)]
		local humanoid = selectedKiller:FindFirstChild("Humanoid") :: Humanoid
		humanoid.Health = 0
		context:Reply(`{selectedKiller.Name} was killed.`, Color3.fromRGB(0, 255, 0))
	else
		local targetKiller = KillerService:GetKillerInRound(name)

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
