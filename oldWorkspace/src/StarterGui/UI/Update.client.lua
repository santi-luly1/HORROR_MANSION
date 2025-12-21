local leaderstats = game.Players.LocalPlayer.leaderstats
local Language = "en"
local Translations = require(game.ReplicatedStorage.Modules.Language)

if string.sub(game.LocalizationService.RobloxLocaleId, 1, 2):lower() == "es" then
	Language = "es"
end

local function updateSurvivals()
	if Language == "es" then
		script.Parent.Survivals.Text = Translations.es.Survivals..": "..leaderstats.Survivals.Value
	else
		script.Parent.Survivals.Text = "Survivals: "..leaderstats.Survivals.Value
	end
end

local function updateCoins()
	if Language == "es" then
		script.Parent.Coins.Text = Translations.es.Coins..": "..leaderstats.Coins.Value
	else
		script.Parent.Coins.Text = "Coins: "..leaderstats.Coins.Value
	end
end

leaderstats.Survivals:GetPropertyChangedSignal'Value':Connect(updateSurvivals)
leaderstats.Coins:GetPropertyChangedSignal'Value':Connect(updateCoins)