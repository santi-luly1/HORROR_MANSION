local DataStores = {}
DataStores.ServiceName = "DataStores"

local DEFAULT = 0

function DataStores:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag provided")

	self._dataStoreService = game:GetService("DataStoreService")
	self._players = game:GetService("Players")

	self._survivals = self._dataStoreService:GetDataStore("Survivals")
	self._coins = self._dataStoreService:GetDataStore("Coins")

	self._name = "Survivals"
	self._name2 = "Coins"
	self._default = DEFAULT
end

-- Returns table: { Surivivals = <num>?, Coins = <num>? }
function DataStores:GetPlayerData(userId)
	local surv, coins
	local ok1, res1 = pcall(function()
		return self._survivals:GetAsync(userId)
	end)
	if ok1 then
		surv = res1
	end

	local ok2, res2 = pcall(function()
		return self._coins:GetAsync(userId)
	end)
	if ok2 then
		coins = res2
	end

	return {
		[self._name] = surv,
		[self._name2] = coins,
	}
end

function DataStores:GetPlayerStat(userId, statName)
	if statName == self._name then
		local ok, res = pcall(function()
			return self._survivals:GetAsync(userId)
		end)
		if ok then
			return res
		end
		return nil, res
	elseif statName == self._name2 then
		local ok, res = pcall(function()
			return self._coins:GetAsync(userId)
		end)
		if ok then
			return res
		end
		return nil, res
	end
	return nil, "Unknown stat"
end

function DataStores:SetPlayerStat(userId, statName, value)
	if statName == self._name then
		pcall(function()
			self._survivals:SetAsync(userId, value)
		end)
		return
	elseif statName == self._name2 then
		pcall(function()
			self._coins:SetAsync(userId, value)
		end)
		return
	end
end

function DataStores:UpdatePlayerStat(userId, statName, delta)
	local current = self:GetPlayerStat(userId, statName)
	if not current then
		current = self._default
	end
	local newVal = (current or 0) + (delta or 0)
	self:SetPlayerStat(userId, statName, newVal)
	return newVal
end

local function onPlayerAdded(self, plr)
	local leaderFolder = Instance.new("Folder")
	leaderFolder.Name = "leaderstats"
	leaderFolder.Parent = plr

	local main = Instance.new("IntValue")
	main.Name = self._name
	main.Value = self._default
	main.Parent = leaderFolder

	local main2 = Instance.new("IntValue")
	main2.Name = self._name2
	main2.Value = self._default
	main2.Parent = leaderFolder

	local ok, err = pcall(function()
		local survivalData = self._survivals:GetAsync(plr.UserId)
		local coinData = self._coins:GetAsync(plr.UserId)
		if survivalData then
			plr.leaderstats[self._name].Value = survivalData
		end
		if coinData then
			plr.leaderstats[self._name2].Value = coinData
		end
	end)

	if not ok then
		warn("DataStores: failed to load for", plr.Name, err)
	end
end

local function onPlayerRemoving(self, plr)
	pcall(function()
		local survVal = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild(self._name)
		local coinVal = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild(self._name2)
		if survVal then
			self._survivals:SetAsync(plr.UserId, survVal.Value)
		end
		if coinVal then
			self._coins:SetAsync(plr.UserId, coinVal.Value)
		end
	end)
end

function DataStores:Start()
	self._players.PlayerAdded:Connect(function(plr)
		onPlayerAdded(self, plr)
	end)
	self._players.PlayerRemoving:Connect(function(plr)
		onPlayerRemoving(self, plr)
	end)
end

return DataStores

