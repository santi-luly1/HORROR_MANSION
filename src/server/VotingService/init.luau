--!strict
--[=[
    @class VotingService
    @author santi-luly1
    @description Server-side map voting manager

    CHANGELOG: [
        03/01/26 --> Initial version.
		03/13/26 --> Ensured StartVoting promise resolves when voting ends early or cancels.
    ]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
-- Roblox services
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Packages
local Maid = require("@game/ReplicatedStorage/Packages/maid")
local Promise = require("@game/ReplicatedStorage/Packages/promise")
local Signal = require("@game/ReplicatedStorage/Packages/signal")
local t = require("@game/ReplicatedStorage/Packages/t")

-- Types
local RoundServiceTypes = require("@game/ServerScriptService/Server/Types/RoundServiceTypes")
local Types = require("@game/ServerScriptService/Server/Types/VotingServiceTypes")

-- Networking
local VotingControllerNet = require("@game/ReplicatedStorage/Network/VotingServiceNetwork")

-- Local utilities
local SpecialMapBehavior = require("@self/SpecialMapBehavior")

-- Services
local RoundService: RoundServiceTypes.RoundService

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local VotingService = {
	_init = false,
	_start = false,
	_isVoting = false,
	_votes = {},
	_mapOptions = {},
	_winningMap = "N/A",
} :: Types.VotingService
VotingService.Dependencies = { "RoundService" }

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local MapsFolder = ServerStorage:WaitForChild("Maps")
local VOTING_DURATION: number

local voteCheck = t.tuple(t.instanceOf("Player"), t.string)

--------------------------------------------------------------------
--- Helpers
--------------------------------------------------------------------
local function getMapData(mapName: string): Types.MapData?
	local map = MapsFolder:FindFirstChild(mapName)
	if not map then
		return nil
	end

	return {
		Name = map.Name,
		Thumbnail = `rbxassetid://{map:GetAttribute("thumbnail_id") or 13239978947}`,
	}
end

local function getRandomMaps(count: number): { string }
	local allMaps = MapsFolder:GetChildren()
	local selected = {}
	local used: { [number]: boolean } = {}

	for _ = 1, count do
		local index
		repeat
			index = math.random(1, #allMaps)
		until not used[index]

		used[index] = true
		table.insert(selected, allMaps[index].Name)
	end

	return selected
end

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function VotingService:Init(registry)
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	RoundService = registry.RoundService
	VOTING_DURATION = RoundService:GetIntermissionTimeout()

	self._maid = Maid.new()
	self.VotingStarted = Signal.new()
	self.VotingEnded = Signal.new()
	self.VoteCast = Signal.new()

	SpecialMapBehavior:Init()

	VotingControllerNet.CastVote.OnServerInvoke = function(player: Player, mapName: string)
		return self:CastVote(player, mapName)
	end

	VotingControllerNet.GetMapOptions.OnServerInvoke = function()
		return self._mapOptions
	end

	VotingControllerNet.GetVotes.OnServerInvoke = function()
		return self:GetVotes()
	end
end

function VotingService:Start()
	assert(self._init, `[{script.Name}] - Module not initialized.`)
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	math.randomseed(os.clock())

	VOTING_DURATION = RoundService:GetIntermissionTimeout()
	self._maid:GiveTask(RoundService.RoundEnded:Connect(function(skipped: boolean)
		if skipped then
			return
		end

		self:StartVoting()
			:andThen(function(winningMap) --TODO: do not hard-code the map's name to "Map"
				workspace.Map:Destroy()
				local newMapClone = MapsFolder[winningMap]:Clone() :: Model
				local mapMaid = Maid.new()
				newMapClone.Parent = workspace
				newMapClone.Name = "Map"

				mapMaid:LinkToInstance(newMapClone)
				SpecialMapBehavior:Get(winningMap):OnMapLoaded(newMapClone, mapMaid)

				for _, player in ipairs(Players:GetPlayers()) do
					player:LoadCharacterAsync()
				end

				--TODO: add an intermission time between map changes, maybe 15s?

				RoundService:Stop("**", true):catch(warn)
			end)
			:catch(warn)
	end))
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function VotingService:StartVoting(mapNames: { string }?): Types.TypedPromise<string>
	return Promise.new(function(resolve, reject, onCancel)
		if self._isVoting then
			return reject("Voting already in progress")
		end

		self._isVoting = true
		local resolved = false
		local function finalize(winner: string)
			if resolved then
				return
			end
			resolved = true
			self._voteResolve = nil
			return resolve(winner)
		end
		self._voteResolve = finalize
		table.clear(self._votes)
		self._winningMap = "N/A"

		local options = mapNames or getRandomMaps(3)
		self._mapOptions = {}

		for _, name in ipairs(options) do
			local data = getMapData(name)
			if data then
				table.insert(self._mapOptions, data)
			end
		end

		if #self._mapOptions == 0 then -- just in case.
			self._isVoting = false
			self._voteResolve = nil
			return reject("No valid maps to vote on")
		end

		VotingControllerNet.VotingStarted:FireAllClients(self._mapOptions, VOTING_DURATION)
		self.VotingStarted:Fire(self._mapOptions)

		local startTime = tick()
		self._countdownThread = task.spawn(function()
			while self._isVoting and tick() - startTime < VOTING_DURATION do
				task.wait(0.1)
			end

			if self._isVoting then
				local winner = self:EndVoting()
				return finalize(winner)
			end
		end)

		if
			onCancel(function()
				self._isVoting = false
				if self._countdownThread then
					task.cancel(self._countdownThread)
				end
				self._voteResolve = nil
				return reject("Voting cancelled")
			end)
		then
			return
		end
	end)
end

function VotingService:EndVoting(): string
	if not self._isVoting then
		return self._winningMap
	end

	self._isVoting = false

	local voteCounts = {} :: { [string]: number }
	for _, mapName in pairs(self._votes) do
		voteCounts[mapName] = (voteCounts[mapName] or 0) + 1
	end

	local maxVotes = 0
	local winner = self._mapOptions[1] and self._mapOptions[1].Name or "N/A"
	local ties: { string } = {}

	for mapName, count in pairs(voteCounts) do
		if count > maxVotes then
			maxVotes = count
			winner = mapName
			table.clear(ties)
			table.insert(ties, mapName)
		elseif count == maxVotes then
			table.insert(ties, mapName)
		end
	end

	if #ties > 1 then
		winner = ties[math.random(1, #ties)]
	end

	self._winningMap = winner

	VotingControllerNet.VotingEnded:FireAllClients(winner, voteCounts)
	self.VotingEnded:Fire(winner, voteCounts)

	if self._voteResolve then
		self._voteResolve(winner)
	end

	return winner
end

function VotingService:CastVote(player: Player, mapName: string): boolean
	if not self._isVoting then
		return false
	end

	local ok, err = voteCheck(player, mapName)
	if not ok then
		warn(`[{script.Name}] Invalid vote: {err}`)
		return false
	end

	local validOption = false
	for _, option in ipairs(self._mapOptions) do
		if option.Name == mapName then
			validOption = true
			break
		end
	end

	if not validOption then
		return false
	end

	local previousVote = self._votes[player]
	self._votes[player] = mapName

	VotingControllerNet.VoteUpdated:FireAllClients(player.UserId, mapName, self:GetVotes())
	self.VoteCast:Fire(player, mapName, previousVote)

	return true
end

function VotingService:GetMapOptions(): { Types.MapData }
	return self._mapOptions
end

function VotingService:GetWinningMap(): string
	return self._winningMap
end

function VotingService:IsVoting(): boolean
	return self._isVoting
end

function VotingService:GetVotes(): { [string]: number }
	local counts: { [string]: number } = {}
	for _, mapName in pairs(self._votes) do
		counts[mapName] = (counts[mapName] or 0) + 1
	end
	return counts
end

return VotingService
