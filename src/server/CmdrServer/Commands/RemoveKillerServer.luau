--!strict
local Services = game:GetService("ServerScriptService").Server

local KillerService = require(Services.KillerService)

return function(context, name: string) -- FIXME: this does not verify if it is the last killer, if it is, this roound will not be skipped.
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
			killer:Kill()
			context:Reply(`{killer.name} was killed.`, Color3.fromRGB(0, 255, 0))
		end
	elseif name == "**" then
		local selectedKiller = currentKillers[math.random(1, #currentKillers)]

		if #currentKillers == 1 then
			selectedKiller.model:SetAttribute("skipRound", true) -- dodgy fix, maybe temporary or permanent.
		end

		selectedKiller:Kill()
		context:Reply(`{selectedKiller.name} was killed.`, Color3.fromRGB(0, 255, 0))
	else
		local targetKiller = KillerService:GetKillerInRound(name)

		if not targetKiller then
			context:Reply(`{name} was not found in round.`, Color3.fromRGB(255, 0, 0))
			return ""
		end

		targetKiller[1]:Kill() -- fix this later.
		context:Reply(`{name} was killed.`, Color3.fromRGB(0, 255, 0))
	end

	return ""
end
