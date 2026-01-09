--!strict
--[=[
	Main API for player data
	@class PlayerDataHandler
	@author: santi-luly1

	CHANGELOG:
		12/25/25 --> Added t module support & methods now returns promises.
		12/26/25 --> Fixed some t validations, new print formatting, fixed C stack overflow error from signal,
					signals fire remotes for the client and now using Promises.try on public APIs.
		12/31/25 --> Added retry/back-off, consistent error handling, fixed isPlayer type-check, added
					profile-versioning, etc.
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Maid = require(Packages:WaitForChild("maid"))
local ProfileStore = require(script:WaitForChild("ProfileStore"))
local Promise = require(Packages:WaitForChild("promise"))
local Signal = require(Packages:WaitForChild("signal"))
local t = require(Packages:WaitForChild("t"))

local PlayerDataNet = require(Networking:WaitForChild("PlayerDataNetwork"))

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local DATASTORE_KEY = RunService:IsStudio() and "Studio" or "Live"
local MAX_RETRIES = 5
local YIELD_PER_RETRY = 2 -- seconds
local PROFILE_VERSION = 1 -- bump when template changes

--------------------------------------------------------------------
--- Template
--------------------------------------------------------------------
local TEMPLATE = {
	Survivals = 0,
	Points = 0,
	Version = PROFILE_VERSION, -- versioning
}

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type Promise<T> = typeof(Promise.new())
export type ValidStats = "Survivals" | "Points"
export type PlayerData = { Survivals: number, Points: number }

local playerCheck = t.instanceOf("Player")
local updateCheck = t.tuple(t.instanceOf("Player"), t.literal("Survivals", "Points"), t.number)

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local PlayerDataHandler = {
	_init = false,
	_start = false,
	_profiles = {} :: {[Player]: any}, -- [Player]: Profile
    _signals  = {} :: {[Player]: any},
}
local SIGNAL_NAMES = {
	Survivals = "SurvivalsChanged",
	Points = "PointsChanged",
}

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function PlayerDataHandler:Init()
	assert(not self._init, `[{script.Name}] already initialized`)
	self._init = true

	self._store = ProfileStore.New(DATASTORE_KEY, TEMPLATE)
	self._profiles = {} -- [Player]: Profile
	self._maids = {} :: {[Player]: Maid.Maid}
	self._signals = {} :: {[Player]: Signal.Signal<>}

	self.ProfileLoaded = Signal.new()
	self.ProfileReleased = Signal.new()
end

function PlayerDataHandler:Start()
	assert(not self._start, `[{script.Name}] already started`)
	self._start = true

	Players.PlayerRemoving:Connect(function(player: Player)
		self:_release(player):catch(warn)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		self:_load(player)
			:andThen(function()
				print(`[{script.Name}] loaded {player.Name}'s profile`)
				self:ClearPlayerData(player)

				task.spawn(function()
					while RunService:IsStudio() do
						task.wait(5)
						
						self:UpdatePlayerStat(player, "Points", 5)
					end
				end)
			end)
			:catch(warn)
	end)

	for _, player in Players:GetPlayers() do -- handle studio early entries
		task.spawn(function()
			self:_load(player):catch(warn)
		end)
	end

	table.freeze(PlayerDataHandler)
end

--------------------------------------------------------------------
--- Core
--------------------------------------------------------------------
function PlayerDataHandler:_load(player: Player): Promise<nil>
	return Promise.new(function(resolve, reject)
		if not playerCheck(player) then
			return reject(`[{script.Name}] bad argument #1 (Player expected)`)
		end

		-- retry with back-off
		local profile
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

		profile:AddUserId(player.UserId)
		profile:Reconcile() -- adds missing keys for old profiles
		if profile.Data.Version ~= PROFILE_VERSION then
			-- simple migration..............
			profile.Data.Version = PROFILE_VERSION
		end

		self._profiles[player] = profile

		local maid = Maid.new()
		self._maids[player] = maid

		local survSig = Signal.new()
		local pointSig = Signal.new()
		self._signals[player] = {
			SurvivalsChanged = survSig,
			PointsChanged = pointSig,
		}

		-- leaderstats
		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
		maid:GiveTask(ls)

		local survVal = Instance.new("IntValue")
		survVal.Name = "Survivals"
		survVal.Value = profile.Data.Survivals
		survVal.Parent = ls
		maid:GiveTask(survVal)

		local pointVal = Instance.new("IntValue")
		pointVal.Name = "Points"
		pointVal.Value = profile.Data.Points
		pointVal.Parent = ls
		maid:GiveTask(pointVal)

		maid:GiveTask(self:ObserveSurvivals(player, function(new)
			survVal.Value = new
			PlayerDataNet.SurvivalsChanged:FireClient(player, new)
		end))
		maid:GiveTask(self:ObservePoints(player, function(new)
			pointVal.Value = new
			PlayerDataNet.PointsChanged:FireClient(player, new)
		end))

		self.ProfileLoaded:Fire(player, profile)
		return resolve() --shut up LLS
	end)
end

function PlayerDataHandler:_release(player: Player): Promise<nil>
	return Promise.new(function(resolve, reject)
		if not playerCheck(player) then
			return reject(`[{script.Name}] bad argument #1 (Player expected)`)
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
		return resolve() --shut up LLS
	end)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function PlayerDataHandler:GetPlayerData(player: Player): Promise<PlayerData>
	return Promise.try(function()
		assert(playerCheck(player))
		local profile = self._profiles[player]
		if not profile then
			error(`[{script.Name}] profile not loaded for {player.Name}`)
		end
		return { Survivals = profile.Data.Survivals, Points = profile.Data.Points }
	end)
end

function PlayerDataHandler:SetPlayerStat(player: Player, statName: ValidStats, value: number): (boolean, string?)
	assert(playerCheck(player) and updateCheck(player, statName, value), `One or more arguments are not valid.`)
	local profile = self._profiles[player]
	if not profile then
		warn(`[{script.Name}] profile not loaded for {player.Name}`)
		return false, "Profile not loaded."
	end

	local current = profile.Data[statName]

	if current == value then
		return true -- we don't need to update something that is not updated.
	end

	profile.Data[statName] = value
	self._signals[player][SIGNAL_NAMES[statName]]:Fire(value)

	return true
end

function PlayerDataHandler:UpdatePlayerStat(player: Player, statName: ValidStats, delta: number): Promise<number>
	return Promise.try(function()
		assert(playerCheck(player) and updateCheck(player, statName, delta), `One or more arguments are not valid.`)
		local profile = self._profiles[player]
		if not profile then
			error(`[{script.Name}] profile not loaded for {player.Name}`)
		end

		local current: number = profile.Data[statName]
		local new = current + delta

		if current == new then
			return new -- we don't need to update something that is not updated.
		end

		profile.Data[statName] = new
		self._signals[player][SIGNAL_NAMES[statName]]:Fire(new)
		return new
	end)
end

function PlayerDataHandler:ObserveSurvivals(player: Player, callback: (number) -> ()): Signal.Connection?
	if not playerCheck(player) then
		return
	end
	local sig = self._signals[player]
	if not sig then
		return warn(`[{script.Name}] signals not ready for {player.Name}`)
	end
	return sig.SurvivalsChanged:Connect(callback)
end

function PlayerDataHandler:ObservePoints(player: Player, callback: (number) -> ()): Signal.Connection?
	if not playerCheck(player) then
		return
	end
	local sig = self._signals[player]
	if not sig then
		return warn(`[{script.Name}] signals not ready for {player.Name}`)
	end
	return sig.PointsChanged:Connect(callback)
end

--------------------------------------------------------------------
--- Studio-only
--------------------------------------------------------------------
function PlayerDataHandler:ClearPlayerData(player: Player)
	if not RunService:IsStudio() then
		return warn(`[{script.Name}] ClearPlayerData can only be used in Studio`)
	end
	self:SetPlayerStat(player, "Survivals", 0)
	self:SetPlayerStat(player, "Points", 0)
end

return PlayerDataHandler
