--[=[
	Main API for player data
    @class DataStores
	@author: santi-luly1

	CHANGELOG: [
		12/25/25 --> Added t module support & methods now returns promises.
		12/26/25 --> Fixed some t validations, new print formatting, fixed C stack overflow error from signal,
					signals fire remotes for the client and now using Promises.try on public APIs.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Remotes = ReplicatedStorage.ServerSignals.DataStores

local Maid = require(Packages.maid)
local ProfileStore = require(Packages.profilestore)
local Promise = require(Packages.promise)
local Signal = require(Packages.signal)
local t = require(Packages.t)

local DataStores = {
	_init = false,
	_start = false,
}
local SIGNAL_NAMES = {
	Survivals = "SurvivalsChanged",
	Points = "PointsChanged",
}

--------------------------------------------------------------------
--- Template
--------------------------------------------------------------------
local TEMPLATE = { Survivals = 0, Points = 0 }

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type Promise<T> = typeof(Promise)
export type ValidStats = "Survivals" | "Points"
export type PlayerData = { Survivals: number, Points: number } --typeof(TEMPLATE)

local playerExpected = t.Instance
local updateStats = t.tuple(t.Instance, t.string, t.number)

local function isPlayer(p: Instance): (boolean, string?)
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
			PointsChanged: Signal.Signal<number>,
		},
	}

	--- signals
	self.ProfileLoaded = Signal.new() -- fired when a profile is loaded
	self.ProfileReleased = Signal.new() -- fired when a profile is released
end

function DataStores:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	Players.PlayerAdded:Connect(function(p: Player)
		self:_load(p)
			:andThen(function()
				print(`[{script.Name}] - Loaded {p.Name}'s profile.`)
				self:UpdatePlayerStat(p, "Survivals", 500) -- just testing.
			end)
			:catch(warn)
	end)

	Players.PlayerRemoving:Connect(function(p: Player)
		self:_release(p)
			:andThen(function()
				print(`[{script.Name}] - Unloaded {p.Name}'s profile.`)
			end)
			:catch(warn)
	end)

	for _, p: Player in Players:GetPlayers() do -- for early players.
		self:_load(p)
			:andThen(function()
				self:UpdatePlayerStat(p, "Survivals", 500) -- just testing.
			end)
			:catch(warn)
	end

	table.freeze(self) -- Prevent accidental modification after module is fully up and running.
end

--------------------------------------------------------------------
--- Core
--------------------------------------------------------------------
function DataStores:_load(player: Player): Promise<nil>
	return Promise.new(function(resolve, reject)
		do -- needed so the variables only live here.
			local _ok, log = isPlayer(player)
			if not _ok then
				reject(`[{script.Name}] - {log}`)
				return
			end
		end

		local profile = self._store:StartSessionAsync(`P_{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
		if not profile then
			reject(`[{script.Name}] - Indexed profile is nil for {player.Name}`)
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
		local pointSig = Signal.new()
		self._signals[player] = {
			SurvivalsChanged = survSig,
			PointsChanged = pointSig,
		}

		-- Build leaderstats
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
				coinVal.Name = "Points"
				coinVal.Value = profile.Data.Points
				coinVal.Parent = ls
				maid:GiveTask(coinVal)
			end

			-- Signal update handlers
			maid:GiveTask(self:ObserveSurvivals(player, function(new)
				survVal.Value = new
				Remotes.SurvivalsChanged:FireClient(player, new)
			end))
			maid:GiveTask(self:ObservePoints(player, function(new)
				coinVal.Value = new
				Remotes.PointsChanged:FireClient(player, new)
			end))
		end

		-- Public events
		self.ProfileLoaded:Fire(player, profile)
		resolve()
	end)
end

function DataStores:_release(player: Player): Promise<nil>
	return Promise.new(function(resolve, reject)
		do -- needed so the variables only live here.
			local _ok, log = isPlayer(player)
			if not _ok then
				reject(`[{script.Name}] - {log}`)
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
			sig.PointsChanged:Destroy()
		end
		self._maids[player] = nil
		self._signals[player] = nil

		local profile = self._profiles[player]
		if profile then
			profile:EndSession()
			self.ProfileReleased:Fire(player, profile)
		end
		self._profiles[player] = nil
		resolve()
	end)
end

function DataStores:_clearData(player: Player) --> Should only be used in studio
	if not RunService:IsStudio() then
		warn(`[{script.Name}] - Tried to clear {player.Name}'s profile while in a live server!`)
		return
	end

	self:SetPlayerStat(player, "Survivals", 0)
	self:SetPlayerStat(player, "Points", 0)
end

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------
function DataStores:GetPlayerData(player: Player): Promise<PlayerData>
	return Promise.try(function()
		assert(isPlayer(player))

		local profile = self._profiles[player]
		if not profile then
			error(`[{script.Name}] - Indexed profile is nil for {player.Name}`)
		end

		return { Survivals = profile.Data.Survivals, Points = profile.Data.Points }
	end)
end

function DataStores:SetPlayerStat(player: Player, statName: ValidStats, value: number)
	assert(isPlayer(player))
	assert(updateStats(player, statName, value))

	local profile = self._profiles[player]
	if not profile then
		warn(`[{script.Name}] - Indexed profile is nil for {player.Name}`)
		return
	end

	profile.Data[statName] = value
	self._signals[player][SIGNAL_NAMES[statName]]:Fire(value)
end

function DataStores:UpdatePlayerStat(player, statName, delta): Promise<number>
	return Promise.try(function()
		assert(isPlayer(player))
		assert(updateStats(player, statName, delta))

		local profile = self._profiles[player]
		if not profile then
			error(`[{script.Name}] - Indexed profile is nil for {player.Name}`)
		end

		local new = profile.Data[statName] + delta
		profile.Data[statName] = new
		self._signals[player][SIGNAL_NAMES[statName]]:Fire(new)
		return new
	end)
end

function DataStores:ObserveSurvivals(player: Player, callback: (number) -> ()): Signal.Connection?
	assert(isPlayer(player))

	local sig = self._signals[player]
	if not sig then
		warn(`[{script.Name}] - Indexed signals is nil for {player.Name}`)
		return
	end

	return sig.SurvivalsChanged:Connect(callback)
end

function DataStores:ObservePoints(player: Player, callback: (number) -> ()): Signal.Connection?
	assert(isPlayer(player))

	local sig = self._signals[player]
	if not sig then
		warn(`[{script.Name}] - Indexed signals is nil for {player.Name}`)
		return
	end

	return sig.PointsChanged:Connect(callback)
end

return DataStores
