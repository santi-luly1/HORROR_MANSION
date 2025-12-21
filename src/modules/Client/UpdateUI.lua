local UpdateUI = {}
UpdateUI.ServiceName = "UpdateUI"

local Players
local LocalizationService
local Translations

local function getLang()
    local locale = LocalizationService.RobloxLocaleId or "en"
    if string.sub(locale, 1, 2):lower() == "es" then
        return "es"
    end
    return "en"
end

function UpdateUI:Init(serviceBag)
    self._serviceBag = serviceBag
    Players = game:GetService("Players")
    LocalizationService = game:GetService("LocalizationService")
    local require = require(script.Parent.loader).load(script)
    Translations = require("Language")
end

function UpdateUI.Start(frame)
    local player = Players.LocalPlayer
    if not player or not player:FindFirstChild("leaderstats") then
        return
    end

    local lang = getLang()
    local leaderstats = player.leaderstats

    local function updateSurvivals()
        if lang == "es" then
            frame.Survivals.Text = Translations.es.Survivals..": "..leaderstats.Survivals.Value
        else
            frame.Survivals.Text = "Survivals: "..leaderstats.Survivals.Value
        end
    end

    local function updateCoins()
        if lang == "es" then
            frame.Coins.Text = Translations.es.Coins..": "..leaderstats.Coins.Value
        else
            frame.Coins.Text = "Coins: "..leaderstats.Coins.Value
        end
    end

    leaderstats.Survivals:GetPropertyChangedSignal("Value"):Connect(updateSurvivals)
    leaderstats.Coins:GetPropertyChangedSignal("Value"):Connect(updateCoins)

    -- initial update
    updateSurvivals()
    updateCoins()
end

return UpdateUI
