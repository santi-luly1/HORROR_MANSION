local PurchasedCoinsGiver = {}
PurchasedCoinsGiver.ServiceName = "PurchasedCoinsGiver"

local require = (require :: any)(script.Parent.loader).load(script)

function PurchasedCoinsGiver:Init(serviceBag)
    assert(not self._serviceBag, "Already initialized")
    self._serviceBag = assert(serviceBag, "No serviceBag provided")
    self._replicatedStorage = game:GetService("ReplicatedStorage")
    self._dataStores = self._serviceBag:GetService(require("DataStores"))
end

function PurchasedCoinsGiver:Start()
    local evt = self._replicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GiveCoins")
    evt.OnServerEvent:Connect(function(player, toGive)
        toGive = tonumber(toGive) or 0
        warn("[Purchasing Coins] Giving ", toGive, " to ", player.Name)
        player.leaderstats.Coins.Value = self._dataStores:UpdatePlayerStat(player.UserId, "Coins", toGive)
    end)
end

return PurchasedCoinsGiver
