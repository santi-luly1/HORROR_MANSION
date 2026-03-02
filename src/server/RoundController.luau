--!strict
--[=[
    Main server game loop handler
	@class RoundController
    @author: santi-luly1

    CHANGELOG: [
		01/21/26 --> Initial version of the module.
		01/28/26 --> Adjusted to the new KillerController and added checks for in-progress rounds.
		02/02/26 --> Display survivors on a Message instance.
		02/14/26 --> If the killer dies, now the round ends with a message, and better hint message.
		02/16/26 --> Better script performance.
		03/01/26 --> Added points rewards once the round ended, signals for round end and start, and GetIntermissionTimeout API.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Packages = game:GetService("ReplicatedStorage").Packages

local Maid = require(Packages.maid)
local Promise = require(Packages:WaitForChild("promise"))
local Signal = require(Packages:WaitForChild("signal"))

local KillerControllerTypes = require(script.Parent.Types.KillerControllerTypes)
local PlayerDataHandlerTypes = require(script.Parent.Types.PlayerDataHandlerTypes)
local Services = require(script.Parent.Services)
local Types = require(script.Parent.Types.RoundControllerTypes)

local KillerController: KillerControllerTypes.KillerController
local PlayerDataHandler: PlayerDataHandlerTypes.PlayerDataHandler

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local RoundController = {
	_init = false,
	_start = false,
	_inProgress = false,
} :: Types.RoundController

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local countdownHint = Instance.new("Hint")
countdownHint.Parent = workspace
local TOTAL_ROUND_DURATION = 120
local ANNOUNCEMENT_LIFETIME = 3
local INTERMISSION_TIMEOUT = 10

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function RoundController:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	self.RoundStarted = Signal.new()
	self.RoundEnded = Signal.new()
end

function RoundController:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	KillerController = Services.WaitFor("KillerController") :: KillerControllerTypes.KillerController
	PlayerDataHandler = Services.WaitFor("PlayerDataHandler") :: PlayerDataHandlerTypes.PlayerDataHandler

	self:Begin("**") -- start the main loop.

	Services.Register(script.Name, self)
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------
function RoundController:_startRound(preferredKiller: string): Types.TypedPromise<{ Model }>
	return Promise.new(function(resolve, reject, onCancel)
		if self._inProgress then
			return reject("Round already in progress")
		end

		self._inProgress = true
		self.RoundStarted:Fire(preferredKiller)

		local maid = Maid.new()
		self._maid = maid

		local cancelled = false
		if onCancel(function()
			cancelled = true
			self:_cleanupRound(maid)
		end) then
			return
		end

		local killersToSpawn: { string }?

		if preferredKiller == "*" then
			killersToSpawn = nil -- SpawnAll handles this
		elseif preferredKiller == "**" then
			local all = {}
			for _, name in ipairs(KillerController:GetKillersName()) do
				if KillerController:IsValidName(name) then
					table.insert(all, name)
				end
			end
			killersToSpawn = { all[math.random(1, #all)] }
		else
			killersToSpawn = { preferredKiller }
		end

		local spawnPromise: Types.TypedPromise<{ Model }> = killersToSpawn
				and KillerController:SpawnKillers(killersToSpawn, -1)
			or KillerController:SpawnAll(-1)

		return spawnPromise
			:andThen(function(initialKillers)
				if cancelled then
					return
				end

				if #initialKillers == 0 then
					self:_cleanupRound(maid)
					return reject("No killers spawned")
				end

				local processedKillers = {} :: { [Model]: boolean } -- killers that already have been setup

				local function setupKillerDeathDetection(killer: Model) -- cleanup and stuff
					if processedKillers[killer] then
						return
					end
					processedKillers[killer] = true

					killer.Destroying:Once(function()
						if self._isEnding or not self._inProgress then
							return
						end

						task.defer(function()
							local remaining = KillerController:GetCurrentKillers()
							if #remaining == 0 and not self._isEnding then -- it was the last killer, so time for cleanup.
								self:Stop():catch(warn)
							else
								local announcement = Instance.new("Message") -- just announce
								announcement.Parent = workspace
								announcement.Text = `{killer.Name} has been killed.`
								Debris:AddItem(announcement, ANNOUNCEMENT_LIFETIME)
							end
						end)
					end)
				end

				for _, killer in ipairs(initialKillers) do -- setup initial killers
					setupKillerDeathDetection(killer)
				end

				maid:GiveTask(KillerController.KillerSpawned:Connect(function(newKiller) -- get new killers mid-round
					if not self._inProgress or self._isEnding then
						return
					end
					setupKillerDeathDetection(newKiller)
				end))

				maid:GiveTask(task.spawn(function()
					local countdown = TOTAL_ROUND_DURATION
					local cachedNames = {} :: { string }
					local cachedCount = -1
					local killerCount = 0

					local function updateCache()
						local currentKillers = KillerController:GetCurrentKillers()
						killerCount = #currentKillers

						if killerCount ~= cachedCount then
							cachedCount = killerCount
							table.clear(cachedNames)
							for _, k in ipairs(currentKillers) do
								table.insert(cachedNames, k.Name)
							end
						end
					end

					maid:GiveTask(
						KillerController.KillerSpawned:Connect(function() -- invalidate cache when new killers spawn
							cachedCount = -1
						end)
					)

					while countdown >= 0 and self._inProgress and not self._isEnding do
						updateCache()

						if killerCount == 0 then
							countdownHint.Text = `No killers.`
							task.wait(3)
							break
						elseif killerCount == 1 then
							countdownHint.Text = `{cachedNames[1]} leaves in {countdown}s`
						else
							if killerCount > 5 then
								countdownHint.Text = `{killerCount} killers will leave in {countdown}s`
							else
								local lastIdx = #cachedNames
								countdownHint.Text =
									`{table.concat(cachedNames, ", ", 1, lastIdx - 1)} and {cachedNames[lastIdx]} will leave in {countdown}s.`
							end
						end

						task.wait(1)
						countdown -= 1
					end

					if self._inProgress and not self._isEnding then
						task.defer(function()
							self:Stop():catch(warn)
						end)
					end
				end))

				return resolve(initialKillers)
			end)
			:catch(function(e)
				self:_cleanupRound(maid)
				reject(e)
			end)
	end)
end

function RoundController:_cleanupRound(maid: Maid.Maid)
	if not self._inProgress then
		return
	end

	self._inProgress = false
	self._isEnding = true
	maid:Destroy()
	KillerController:Clear()
	self._maid = nil
end

function RoundController:_intermissionCountdown(skipped: boolean): Types.TypedPromise<()>
	return Promise.new(function(resolve)
		task.spawn(function()
			for i = INTERMISSION_TIMEOUT, 0, -1 do
				countdownHint.Text = `Round {skipped and "skipped" or "ended"} - Starting next round in {i}s...`
				task.wait(1)
			end
			return resolve()
		end)
	end)
end

function RoundController:_endRound(preferredKiller: string, skipped: boolean): Types.TypedPromise<()>
	return Promise.new(function(resolve, reject)
		if not skipped then -- start command for example would skip the round, so it doesn't really count as a survival
			local survivors = {} :: { string }
			local survivorPlayers = {} :: { Player }
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("Dead") == false then
					table.insert(survivors, player.Name)
					table.insert(survivorPlayers, player)
					PlayerDataHandler:UpdatePlayerStat(player, "Survivals", 1)
				else
					player:SetAttribute("Dead", false) -- just reset back the attribute
				end
			end

			local announcement = Instance.new("Message") -- TODO: maybe make it a little notification?
			announcement.Parent = workspace

			if #survivors == 0 then
				announcement.Text = "No survivors."
			elseif #survivors == 1 then
				announcement.Text = `Survivor: {survivors[1]}.`
			else
				table.sort(survivors)
				local lastIdx = #survivors
				announcement.Text =
					`Survivors: {table.concat(survivors, ", ", 1, lastIdx - 1)} and {survivors[lastIdx]}.`
			end
			Debris:AddItem(announcement, ANNOUNCEMENT_LIFETIME)

			for _, survivorPlayer in ipairs(survivorPlayers) do
				PlayerDataHandler:UpdatePlayerStat(survivorPlayer, "Points", 25):catch(warn) -- TODO: Maybe instead of giving a fixed ammount, give points based off the survival duration?
			end

			task.wait(ANNOUNCEMENT_LIFETIME) -- little gap between the survivors and the actual intermission
		end

		self.RoundEnded:Fire(skipped or false) -- maybe its name would be better if it was smth like "OnIntermission"

		self:_intermissionCountdown(skipped)
			:andThen(function()
				self._isEnding = false
				return self:Begin(preferredKiller) -- TODO: probably add duos or just multiple killers to survive?
			end)
			:andThen(resolve)
			:catch(reject)
	end)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function RoundController:Begin(preferredKiller: string): Types.TypedPromise<{ Model }>
	if self:OnIntermission() then
		return Promise.reject("Cannot start round during intermission")
	end

	if self._inProgress then
		return self:Stop(preferredKiller, true):andThen(function()
			return self:_startRound(preferredKiller)
		end)
	end

	return self:_startRound(preferredKiller)
end

function RoundController:OnIntermission(): boolean
	return self._isEnding and not self._inProgress
end

function RoundController:Stop(preferredKiller: string?, skipped: boolean?): Types.TypedPromise<()>
	if self._isEnding then
		return Promise.reject("Round already ending")
	end
	self._isEnding = true

	if self._maid then
		self:_cleanupRound(self._maid)
	end

	if not self._isEnding then
		return Promise.resolve()
	end

	return self:_endRound(preferredKiller or "**", skipped or false)
end

function RoundController:GetIntermissionTimeout(): number
	return INTERMISSION_TIMEOUT
end

return RoundController
