--[=[
	Main API for player data
    @class DataStores
	@author: santi-luly1

	CHANGELOG: [
		12/25/25 --> Added t module support & methods now returns promises.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Packages = game:GetService("ReplicatedStorage").Packages

local Maid = require(Packages.maid)
local ProfileStore = require(Packages.profilestore)
local Promise = require(Packages.promise)
local Signal = require(Packages.signal)
local t = require(Packages.t)

local DataStores = {
	_init = false,
	_start = false,
}

--------------------------------------------------------------------
--- Template
--------------------------------------------------------------------
local TEMPLATE = { Survivals = 0, Coins = 0 }

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type VALID_STATS = "Survivals" | "Coins"
local playerExpected = t.Instance
local updateStats = t.tuple(t.Instance, t.string, t.number)

local function isPlayer(p: Instance)
	local _ok, log = playerExpected(p)
	if not _ok then
		return false, log
	end

	if not p:IsA("Player") then
		return false, "Parameter is not a Player."
	end

	return true
end

--------------------------------------------------------------------
--- ServiceBag (not currently using service bag)
--------------------------------------------------------------------
function DataStores:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	self._store = ProfileStore.New(RunService:IsStudio() and "Studio" or "Live", TEMPLATE)
	self._profiles = {} :: {
		[Player]: typeof(self._store:StartSessionAsync()), -- ProfileStore.Profile<any>
	}
	self._maids = {} :: {
		[Player]: Maid.Maid,
	}
	self._signals = {} :: {
		[Player]: {
			SurvivalsChanged: Signal.Signal<number>,
			CoinsChanged: Signal.Signal<number>,
		},
	}

	--- signals
	self.ProfileLoaded = Signal.new() -- fired when a profile is loaded
	self.OnUpdate = Signal.new() -- fired when a profile is updated
	self.ProfileReleased = Signal.new() -- fired when a profile is released
end

function DataStores:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	Players.PlayerAdded:Connect(function(p: Player)
		self:_load(p)
			:andThen(function(ok: boolean, log: string)
				if ok then
					print(`[{script.Name}] - Loaded {p.Name}'s profile.`)
				else
					print(`[{script.Name}] - Couldn't load {p.Name}'s profile. Log:\n{log}`)
				end

				self:UpdatePlayerStat(605354831, "Survivals", 500) -- just testing.
			end)
			:catch(warn)
	end)

	Players.PlayerRemoving:Connect(function(p: Player)
		self:_release(p)
			:andThen(function(ok: boolean, log: string)
				if ok then
					print(`[{script.Name}] - Unloaded {p.Name}'s profile.`)
				else
					print(`[{script.Name}] - Couldn't unload {p.Name}'s profile. Log:\n{log}`)
				end

				self:UpdatePlayerStat(605354831, "Survivals", 500) -- just testing.
			end)
			:catch(warn)
	end)

	for _, p: Player in Players:GetPlayers() do -- for early players.
		self:_load(p)
			:andThen(function(ok: boolean, log: string)
				if ok then
					print(`[{script.Name}] - Loaded {p.Name}'s profile.`)
				else
					print(`[{script.Name}] - Couldn't load {p.Name}'s profile. Log:\n{log}`)
				end

				self:UpdatePlayerStat(605354831, "Survivals", 500) -- just testing.
			end)
			:catch(warn)
	end
end

--------------------------------------------------------------------
--- Core
--------------------------------------------------------------------
function DataStores:_load(player: Player): any --> Promise.Promise<boolean>
	return Promise.new(function(resolve, reject)
		do -- needed so the variables only live here.
			local _ok, log = isPlayer(player)
			if not _ok then
				reject(_ok, log)
				return
			end
		end

		local profile = self._store:StartSessionAsync(`P_{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
		if not profile then
			reject(false, "profile = nil")
			player:Kick(
				"Failed to get your data loaded, and decided to prevent data loss by kicking you. Please rejoin!"
			)
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
		do
			local ls = Instance.new("Folder")
			do
				ls.Name = "leaderstats"
				ls.Parent = player
				maid:GiveTask(ls)
			end

			local survVal = Instance.new("IntValue")
			do
				survVal.Name = "Survivals"
				survVal.Value = profile.Data.Survivals
				survVal.Parent = ls
				maid:GiveTask(survVal)
			end

			local coinVal = Instance.new("IntValue")
			do
				coinVal.Name = "Coins"
				coinVal.Value = profile.Data.Coins
				coinVal.Parent = ls
				maid:GiveTask(coinVal)
			end

			-- Signal update handlers
			maid:GiveTask(self:ObserveSurvivals(player, function(new)
				survVal.Value = new
				survSig:Fire(new)
			end))
			maid:GiveTask(self:ObserveCoins(player, function(new)
				coinVal.Value = new
				coinSig:Fire(new)
			end))
		end

		-- Public events
		self.ProfileLoaded:Fire(player, profile)
		resolve(true)
	end)
end

function DataStores:_release(player: Player): any --> Promise.Promise<boolean>
	return Promise.new(function(resolve, reject)
		do -- needed so the variables only live here.
			local _ok, log = isPlayer(player)
			if not _ok then
				reject(_ok, log)
				return
			end
		end

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
		player:Kick("Session ended.")
		resolve(true)
	end)
end

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------
function DataStores:GetPlayerData(player: Player): any --> Promise.Promise<boolean>
	return Promise.new(function(resolve, reject)
		do -- needed so the variables only live here.
			local _ok, log = isPlayer(player)
			if not _ok then
				reject(_ok, log)
				return
			end
		end

		local profile = self._profiles[player]
		if not profile then
			reject(false, `{player.Name}'s profile was not found.`)
			return
		end

		resolve {
			Survivals = profile.Data.Survivals,
			Coins = profile.Data.Coins,
		}
	end)
end

function DataStores:SetPlayerStat(player: Player, statName: VALID_STATS, value: number)
	assert(updateStats(player, statName, value))

	local profile = self._profiles[player]
	if not profile then
		warn(`[{script.Name}] - No profile for player {player.Name}, no value set!`)
		return
	end

	profile.Data[statName] = value
	self._signals[player][`{statName}Changed`]:Fire(value)
	self.OnUpdate:Fire(player, statName, value)
end

function DataStores:UpdatePlayerStat(player: Player, statName: VALID_STATS, delta: number): any --> Promise.Promise<boolean>
	return Promise.new(function(resolve, reject)
		do -- needed so the variables only live here.
			local _ok, log = isPlayer(player)
			if not _ok then
				reject(_ok, log)
				return
			end
		end

		local profile = self._profiles[player]
		if not profile then
			reject(false, `[{script.Name}] - No profile for player {player.Name}, no update!`)
			return
		end

		local new: number = profile.Data[statName] + delta
		profile.Data[statName] = new
		self._signals[player][`{statName}Changed`]:Fire(new)
		self.OnUpdate:Fire(player, statName, new)

		resolve(true, new)
	end)
end

function DataStores:ObserveSurvivals(player: Player, callback: (number) -> ()): Signal.Connection | () -> ()
	local sig = self._signals[player]
	if not sig then
		return function() end
	end -- dummy disconnect
	return sig.SurvivalsChanged:Connect(callback)
end

function DataStores:ObserveCoins(player: Player, callback: (number) -> ()): Signal.Connection | () -> ()
	local sig = self._signals[player]
	if not sig then
		return function() end
	end
	return sig.CoinsChanged:Connect(callback)
end

return DataStores
