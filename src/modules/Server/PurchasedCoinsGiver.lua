local PurchasedCoinsGiver = {}
PurchasedCoinsGiver.ServiceName = "PurchasedCoinsGiver"

local require = require(script.Parent.loader).load(script)

function PurchasedCoinsGiver:Init(serviceBag)
    assert(not self._serviceBag, "Already initialized")
    self._serviceBag = assert(serviceBag, "No serviceBag provided")
    self._replicatedStorage = game:GetService("ReplicatedStorage")
end

function PurchasedCoinsGiver:Start()
    local evt = self._replicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GiveCoins")
    evt.OnServerEvent:Connect(function(player, toGive)
        local amount = tonumber(toGive) or 0
        warn("[Purchasing Coins] Giving ", amount, " to ", player.Name)
        local dataStores
        if self._serviceBag then
            local ok, ds = pcall(function()
                return self._serviceBag:GetService(require("DataStores"))
            end)
            if ok then
                dataStores = ds
            end
        end

        if dataStores then
            local newVal = dataStores:UpdatePlayerStat(player.UserId, "Coins", amount)
            if player and player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins") then
                player.leaderstats.Coins.Value = newVal
            end
        else
            if player and player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins") then
                player.leaderstats.Coins.Value = player.leaderstats.Coins.Value + amount
            end
        end
    end)
end

return PurchasedCoinsGiver
