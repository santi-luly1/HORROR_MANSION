--!strict
--[=[
	@class PlayerDataService
    @author santi-luly1
	@description Main API for player data

	CHANGELOG:
		12/25/25 --> Added t module support & methods now returns promises.
		12/26/25 --> Fixed some t validations, new print formatting, fixed C stack overflow error from signal, signals
					fire remotes for the client and now using Promises.try on public APIs.
		12/31/25 --> Added retry/back-off, consistent error handling, fixed isPlayer type-check, added profile-versioning, etc.
		01/09/26 --> Added Promise typechecking.
		01/11/26 --> Entire module is now typechecked.
		01/30/26 --> Removed Promise.try for a better Promise chain.
		02/16/26 --> Fixed race conditions.
		03/13/26 --> Added signal checks to avoid stat updates during player removal (AI).
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
-- Roblox services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Packages
local Maid = require("@packages/maid")
local ProfileStore = require("@serverPackages/profilestore")
local Promise = require("@packages/promise")
local Signal = require("@packages/signal")
local t = require("@packages/t")

-- Types
local Types = require("@serverTypes/PlayerDataServiceTypes")

-- Networking
local Networking = require("@network/PlayerDataNetwork")

-- Local utilities

-- Services

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local PlayerDataService = {
	_init = false,
	_start = false,
	_profiles = {},
	_maids = {},
	_signals = {},
	_loadingPromises = {}, -- track in-progress loads to prevent race conditions
} :: Types.PlayerDataService

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local DATASTORE_KEY = RunService:IsStudio() and "Studio" or "Live"
local MAX_RETRIES = 5
local YIELD_PER_RETRY = 2 -- seconds
local PROFILE_VERSION = 1 -- bump when template changes
local SIGNAL_NAMES = {
	Survivals = "SurvivalsChanged",
	Points = "PointsChanged",
} :: { [Types.ValidStats]: string }

--------------------------------------------------------------------
--- Template
--------------------------------------------------------------------
local TEMPLATE = {
	Survivals = 0,
	Points = 0,
	Version = PROFILE_VERSION, -- versioning
} :: Types.PlayerData

local playerCheck = t.instanceOf("Player")
local updateCheck = t.tuple(t.instanceOf("Player"), t.literal("Survivals", "Points"), t.number)

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function PlayerDataService:Init()
	assert(not self._init, `[{script.Name}] already initialized`)
	self._init = true

	self._store = ProfileStore.New(DATASTORE_KEY, TEMPLATE)

	self.ProfileLoaded = Signal.new() :: Types.ProfileStateChangedSignal
	self.ProfileReleased = Signal.new() :: Types.ProfileStateChangedSignal
end

function PlayerDataService:Start()
	assert(not self._start, `[{script.Name}] already started`)
	self._start = true

	Players.PlayerRemoving:Connect(function(player: Player)
		self:_release(player):catch(warn)
	end)

	local function createProfileForPlayer(player: Player)
		self:_load(player)
			:andThen(function()
				print(`[{script.Name}] loaded {player.Name}'s profile`)
			end)
			:catch(warn)
	end

	Players.PlayerAdded:Connect(createProfileForPlayer)

	for _, player in Players:GetPlayers() do -- handle studio early entries
		task.spawn(function()
			createProfileForPlayer(player)
		end)
	end
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------
function PlayerDataService:_load(player: Player): Types.TypedPromise<Types.PlayerProfile>
	if self._loadingPromises[player] then
		return self._loadingPromises[player]
	end

	local promise = Promise.new(function(resolve, reject)
		local ok, err = playerCheck(player)
		if not ok then
			return reject(`[{script.Name}] {err}`)
		end

		-- retry with back-off
		local profile: Types.PlayerProfile?
		for attempt = 1, MAX_RETRIES do
			profile = self._store:StartSessionAsync(`P_{player.UserId}`, {
				Cancel = function()
					return player.Parent ~= Players
				end,
			})
			if profile then
				break
			end
			task.wait(YIELD_PER_RETRY * (2 ^ (attempt - 1))) -- exponential
		end
		if not profile then
			return reject(`[{script.Name}] could not load profile for {player.Name} after {MAX_RETRIES} tries`)
		end

		-- just in case it's "corrupted" or whatever
		if not profile.Data or type(profile.Data) ~= "table" then
			profile:EndSession()
			return reject(`[{script.Name}] invalid profile data for {player.Name}`)
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile() -- adds missing keys for old profiles

		if profile.Data.Version ~= PROFILE_VERSION then
			-- simple migration..............
			-- TODO: actual migration
			profile.Data.Version = PROFILE_VERSION
		end

		self._profiles[player] = profile

		local maid = Maid.new() -- would LinkToInstance be worth it in here?
		self._maids[player] = maid

		self._signals[player] = {
			SurvivalsChanged = Signal.new(),
			PointsChanged = Signal.new(),
		}

		-- leaderstats
		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
		maid:GiveTask(ls)

		local survVal = Instance.new("IntValue")
		survVal.Name = "Survivals"
		survVal.Parent = ls
		survVal.Value = profile.Data.Survivals
		maid:GiveTask(survVal)

		local pointVal = Instance.new("IntValue")
		pointVal.Name = "Points"
		pointVal.Parent = ls
		pointVal.Value = profile.Data.Points
		maid:GiveTask(pointVal)

		self:ObserveSurvivals(player, function(new)
			survVal.Value = new
			Networking.SurvivalsChanged:FireClient(player, new)
		end)
			:andThen(function(connection)
				maid:GiveTask(connection)
			end)
			:catch(function(e)
				warn(`[{script.Name}] Failed to observe {player.Name}'s survivals, expect visual bugs: {e}`)
			end)

		self:ObservePoints(player, function(new)
			pointVal.Value = new
			Networking.PointsChanged:FireClient(player, new)
		end)
			:andThen(function(connection)
				maid:GiveTask(connection)
			end)
			:catch(function(e)
				warn(`[{script.Name}] Failed to observe {player.Name}'s points, expect visual bugs: {e}`)
			end)

		self.ProfileLoaded:Fire(player, profile)
		return resolve(profile)
	end)

	self._loadingPromises[player] = promise
	promise:finally(function()
		self._loadingPromises[player] = nil
	end)

	return promise
end

function PlayerDataService:_release(player: Player): Types.TypedPromise<()>
	return Promise.new(function(resolve, reject)
		local ok, err = playerCheck(player)
		if not ok then
			return reject(`[{script.Name}] {err}`)
		end

		if self._loadingPromises[player] then
			self._loadingPromises[player]:await()
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
		return resolve()
	end)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function PlayerDataService:GetPlayerData(player: Player): Types.TypedPromise<Types.PlayerData>
	return Promise.new(function(resolve, reject)
		local ok, err = playerCheck(player)
		if not ok then
			return reject(`[{script.Name}] {err}`)
		end

		local profile = self._profiles[player]
		if not profile then
			return reject(`[{script.Name}] profile not loaded for {player.Name}`)
		end

		resolve({
			Survivals = profile.Data.Survivals,
			Points = profile.Data.Points,
			Version = profile.Data.Version,
		})
	end)
end

function PlayerDataService:SetPlayerStat(
	player: Player,
	statName: Types.ValidStats,
	value: number
): Types.TypedPromise<boolean>
	return Promise.new(function(resolve, reject)
		local ok, err = updateCheck(player, statName, value)
		if not ok then
			return reject(`[{script.Name}] {err}`)
		end

		local profile = self._profiles[player]
		if not profile then
			return reject(`[{script.Name}] profile not loaded for {player.Name}`)
		end

		local sig = self._signals[player]
		if not sig then
			return reject(`[{script.Name}] signals not initialized for {player.Name}`)
		end

		local data = profile.Data :: Types.PlayerData
		if data[statName] == value then
			return resolve(true)
		end

		data[statName] = value
		sig[SIGNAL_NAMES[statName]]:Fire(value)
		return resolve(true)
	end)
end

function PlayerDataService:UpdatePlayerStat(
	player: Player,
	statName: Types.ValidStats,
	delta: number
): Types.TypedPromise<number>
	return Promise.new(function(resolve, reject)
		local ok, err = updateCheck(player, statName, delta)
		if not ok then
			return reject(`[{script.Name}] {err}`)
		end

		local profile = self._profiles[player]
		if not profile then
			return reject(`[{script.Name}] profile not loaded for {player.Name}`)
		end

		local sig = self._signals[player]
		if not sig then
			return reject(`[{script.Name}] signals not initialized for {player.Name}`)
		end

		local data = profile.Data :: Types.PlayerData
		local newValue = data[statName] + delta

		if data[statName] == newValue then
			return resolve(newValue) -- we don't need to update something that is not updated.
		end

		data[statName] = newValue
		sig[SIGNAL_NAMES[statName]]:Fire(newValue)
		return resolve(newValue)
	end)
end

function PlayerDataService:ObserveSurvivals(
	player: Player,
	callback: (newValue: number) -> ()
): Types.TypedPromise<Signal.Connection>
	return Promise.new(function(resolve, reject)
		local ok, err = playerCheck(player)
		if not ok then
			return reject(`[{script.Name}] {err}`)
		end

		local sig = self._signals[player]
		if not sig then
			return reject(`[{script.Name}] signals not initialized for {player.Name}`)
		end

		return resolve(sig.SurvivalsChanged:Connect(callback))
	end)
end

function PlayerDataService:ObservePoints(
	player: Player,
	callback: (newValue: number) -> ()
): Types.TypedPromise<Signal.Connection>
	return Promise.new(function(resolve, reject)
		local ok, err = playerCheck(player)
		if not ok then
			return reject(`[{script.Name}] {err}`)
		end

		local sig = self._signals[player]
		if not sig then
			return reject(`[{script.Name}] signals not initialized for {player.Name}`)
		end

		return resolve(sig.PointsChanged:Connect(callback))
	end)
end

--------------------------------------------------------------------
--- Studio-only
--------------------------------------------------------------------
function PlayerDataService:ClearPlayerData(player: Player): Types.TypedPromise<boolean>
	if not RunService:IsStudio() then
		return Promise.reject(`[{script.Name}] ClearPlayerData can only be used in Studio`)
	end

	local ok, err = playerCheck(player)
	if not ok then
		return Promise.reject(`[{script.Name}] {err}`)
	end

	return Promise.all({
		self:SetPlayerStat(player, "Survivals", 0),
		self:SetPlayerStat(player, "Points", 0),
	}):andThen(function()
		return true
	end)
end

return PlayerDataService
