--[=[
	Main API player data
    @class DataStores
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")
local Packages = game:GetService("ReplicatedStorage").Packages

local Maid = require(Packages.maid)
local ProfileStore = require(Packages.profilestore)
local Promise = require(Packages.promise)
local Signal = require(Packages.signal)

local DataStores = {}
DataStores.ServiceName = "DataStores"

--------------------------------------------------------------------
--- Template
--------------------------------------------------------------------
local TEMPLATE = { Survivals = 0, Coins = 0 }

--------------------------------------------------------------------
--- ServiceBag
--------------------------------------------------------------------
function DataStores:Init(serviceBag)
	assert(not self._serviceBag, "Already initialised")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._store = ProfileStore.New("Survivals", TEMPLATE)
	self._profiles = {} :: {
		[Player]: typeof(ProfileStore),--Types.Profile, -- TODO: Maybe implement this type.
	}
	self._maids = {} :: {
		[Player]: Maid.Maid,
	}
	self._signals = {} :: {
		[Player]: {
			SurvivalsChanged: Signal.Signal<number>,
			CoinsChanged: Signal.Signal<number>,
		}
	}

	--- signals
	self.ProfileLoaded = Signal.new()
	self.OnUpdate = Signal.new()
	self.ProfileReleased = Signal.new()
end

function DataStores:Start()
	Players.PlayerAdded:Connect(function(p: Player)
		print(Promise)
		print(self:_load(p))
		--:catch(warn)
	end)
	Players.PlayerRemoving:Connect(function(p: Player)
		self:_release(p)
	end)
	for _, p: Player in Players:GetPlayers() do
		self:_load(p):catch(warn)
	end
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function DataStores:_load(player: Player): any --> Promise.Promise<boolean>
	return Promise.new(function(resolve, reject)
		if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then -- just making sure, a bit redundant, but me and my clumsiness.
			reject(`First argument must be a player instance, got {typeof(player)}.`)
			return
		end

		local profile = self._store:StartSessionAsync(tostring(player.UserId), {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
		if not profile then
			reject("ProfileStore session fail")
			player:Kick("Failed to get your data loaded, and decided to prevent data loss by kicking you. Please rejoin!")
			return
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile()

		--- Store profile
		self._profiles[player] = profile

		--- Maid for this player
		local maid = Maid.new()
		self._maids[player] = maid

		-- Signals for this player
		local survSig = Signal.new()
		local coinSig = Signal.new()
		self._signals[player] = {
			SurvivalsChanged = survSig,
			CoinsChanged = coinSig,
		}

		-- Build leaderstats exactly like the old code
		local ls = Instance.new("Folder")
		do
			ls.Name = "leaderstats"
			ls.Parent = player
			maid:Add(ls)
		end

		local survVal = Instance.new("IntValue")
		do
			survVal.Name = "Survivals"
			survVal.Value = profile.Data.Survivals
			survVal.Parent = ls
			maid:Add(survVal)
		end

		local coinVal = Instance.new("IntValue")
		do
			coinVal.Name = "Coins"
			coinVal.Value = profile.Data.Coins
			coinVal.Parent = ls
			maid:Add(coinVal)
		end

		-- Signal update handlers
		maid:Add(self:ObserveSurvivals(player, function(new)
			survVal.Value = new
			survSig:Fire(new)
		end))
		maid:Add(self:ObserveCoins(player, function(new)
			coinVal.Value = new
			coinSig:Fire(new)
		end))

		-- Public events
		self.ProfileLoaded:Fire(player, profile)
		resolve(true)
	end)
end

function DataStores:_release(player: Player)
	local maid = self._maids[player]
	local sig = self._signals[player]
	if maid then
		maid:Destroy()
	end
	if sig then
		sig.SurvivalsChanged:Destroy()
		sig.CoinsChanged:Destroy()
	end
	self._maids[player] = nil
	self._signals[player] = nil

	local profile = self._profiles[player]
	if profile then
		profile:EndSession()
		self.ProfileReleased:Fire(player, profile)
	end
	self._profiles[player] = nil
end

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------
function DataStores:GetPlayerData(userId: number): typeof(TEMPLATE)
	local player = Players:GetPlayerByUserId(userId)
	local profile = player and self._profiles[player]
	if not profile then
		warn(`[DataStores] - No profile for userId {userId}, returning template!`)
		return TEMPLATE
	end

	return {
		Survivals = profile.Data.Survivals,
		Coins = profile.Data.Coins,
	}
end

function DataStores:GetPlayerStat(userId: number, statName: string): any?
	local data = self:GetPlayerData(userId)
	return data[statName]
end

function DataStores:SetPlayerStat(userId: number, statName: string, value: any)
	local player = Players:GetPlayerByUserId(userId)
	local profile = player and self._profiles[player]
	if not profile then
		warn(`[DataStores] - No profile for userId {userId}, no value set!`)
		return
	end

	profile.Data[statName] = value
end

function DataStores:UpdatePlayerStat(userId: number, statName: string, delta: number): number?
	local player = Players:GetPlayerByUserId(userId)
	local profile = player and self._profiles[player]
	if not profile then
		warn(`[DataStores] - No profile for userId {userId}, returning template!`)
		return
	end

	local new: number = (profile.Data[statName] or 0) + delta
	profile.Data[statName] = new
	return new
end

function DataStores:PromisePlayerData(player: Player): any --> Promise.Promise<boolean>
	-- Resolves instantly if already loaded, else waits for the load promise
	if self._profiles[player] then
		return Promise.resolve(self._profiles[player])
	end
	-- We already fired :_load on PlayerAdded, so just await it
	return self:_load(player)
end

function DataStores:ObserveSurvivals(player: Player, callback: (number) -> ())
	local sig = self._signals[player]
	if not sig then
		return function() end
	end -- dummy disconnect
	return sig.SurvivalsChanged:Connect(callback)
end

function DataStores:ObserveCoins(player: Player, callback: (number) -> ())
	local sig = self._signals[player]
	if not sig then
		return function() end
	end
	return sig.CoinsChanged:Connect(callback)
end

return DataStores
