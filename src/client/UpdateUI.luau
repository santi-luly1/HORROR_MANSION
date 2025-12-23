local UpdateUI = {}
UpdateUI.ServiceName = "UpdateUI"

local Players
function UpdateUI:Init(serviceBag)
	self._serviceBag = serviceBag
	Players = game:GetService("Players")
end

function UpdateUI.Start(frame)
	local player = Players.LocalPlayer
	if not player or not player:FindFirstChild("leaderstats") then
		return
	end

	local leaderstats = player.leaderstats

	local function updateSurvivals()
		frame.Survivals.Text = "Survivals: " .. leaderstats.Survivals.Value
	end

	local function updateCoins()
		frame.Coins.Text = "Coins: " .. leaderstats.Coins.Value
	end

	leaderstats.Survivals:GetPropertyChangedSignal("Value"):Connect(updateSurvivals)
	leaderstats.Coins:GetPropertyChangedSignal("Value"):Connect(updateCoins)

	-- initial update
	updateSurvivals()
	updateCoins()
end

return UpdateUI
