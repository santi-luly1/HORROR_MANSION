--!strict
--[=[
    Main server game loop handler
	@class GameLoop
    @author: santi-luly1

    CHANGELOG: [
		01/21/26 --> Initial version of the module.
		01/28/26 --> Adjusted to the new KillerController and added checks for in-progress rounds.
		02/02/26 --> Display survivors on a Message instance.
		02/14/26 --> If the killer dies, now the round ends with a message, and better hint message.
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

local KillerController = require(script.Parent.KillerController)
local PlayerDataHandler = require(script.Parent.PlayerDataHandler)

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local GameLoop = {
	_init = false,
	_start = false,
	_inProgress = false,
} :: GameLoop

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local countdownHint = Instance.new("Hint")
do
	countdownHint.Parent = workspace
end
local TOTAL_ROUND_DURATION = 20

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type TypedPromise<T...> = Promise.TypedPromise<T...>

type GameLoop = {
	-- lifecycle
	Init: (self: GameLoop) -> (),
	Start: (self: GameLoop) -> (),

	-- public API
	Begin: (self: GameLoop, preferredKiller: string) -> TypedPromise<{ Model }>,
	Stop: (self: GameLoop) -> TypedPromise<{ Model }>,

	-- events

	-- private
	_init: boolean,
	_start: boolean,
	_inProgress: boolean,
	_isEnded: boolean,
	_maid: Maid.Maid,

	-- private methods
	_startRound: (self: GameLoop, preferredKiller: string) -> TypedPromise<{ Model }>,
	_endRound: (self: GameLoop) -> TypedPromise<{ Model }>,
}

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function GameLoop:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true
end

function GameLoop:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	self._maid = Maid.new()

	self:_endRound() -- start the main loop.
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function GameLoop:_startRound(preferredKiller: string): TypedPromise<{ Model }>
	return Promise.new(function(resolve, reject, onCancel)
		local cancelled = false
		if onCancel(function()
			cancelled = true
			self:_endRound()
		end) then
			return
		end

		if self._inProgress then
			return reject("Round already in progress")
		end

		self._inProgress = true

		local maid = Maid.new()
		self._maid:GiveTask(maid)

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

		local spawnPromise: TypedPromise<{ Model }> = killersToSpawn
				and KillerController:SpawnKillers(killersToSpawn, -1)
			or KillerController:SpawnAll(-1)

		spawnPromise
			:andThen(function(killers)
				if cancelled then
					return
				end

				if #killers == 0 then
					maid:Destroy()
					return reject("No killers spawned")
				end

				maid:GiveTask(function() -- cleanup and stuff
					self._inProgress = false
					KillerController:Clear()

					-- in case the killer dies, the round would have to end.
					if not self._isEnded then
						self:_endRound():catch(warn)
					end
				end)

				for i, killer in ipairs(killers) do -- FIXME: little bug that creates "Ghost" killers, happens when you start with multiple killers, and kill one of them while the round is freshly starting (or while the Messages are up)
					killer.Destroying:Once(function() -- make a new announcement for every killer killed
						if self._isEnded or not self._inProgress then
							return
						end

						local announcement = Instance.new("Message")
						announcement.Parent = workspace

						if #killers <= 1 then
							announcement.Text = `All killers have been defeated.`
							table.remove(killers, i)
							Debris:AddItem(announcement, 3)
							task.wait(3)
							return maid:Destroy() -- it was the last killer, so time for cleanup.
						end

						announcement.Text = `{killer.Name} has been killed.`
						table.remove(killers, i)
						Debris:AddItem(announcement, 3)
					end)
				end

				maid:GiveTask(task.spawn(function()
					local countdown = TOTAL_ROUND_DURATION

					while countdown >= 0 do
						if #killers == 0 then
							countdownHint.Text = `No killers.`
							task.wait(3)
							break
						elseif #killers == 1 then
							countdownHint.Text = `{killers[1].Name} leaves in {countdown}s`
						else
							if #killers > 5 then -- nested ifs = ugly?????
								countdownHint.Text = `{#killers} killers will leave in {countdown}s`
							else
								local namesTable = {}
								for _, killer in ipairs(killers) do -- TODO: we're on a while loop, this just kills performance, UPDATE IT AAAAAAAAAAAAAAAAAAAAAAAAAAAAA
									table.insert(namesTable, killer.Name)
								end
								countdownHint.Text =
									`{table.concat(namesTable, ", ", nil, #namesTable - 1)} and {namesTable[#namesTable]} will leave in {countdown}s.`
							end
						end

						task.wait(1)
						countdown -= 1
					end

					task.defer(function()
						self:_endRound():catch(warn)
					end)
				end))

				return resolve(killers)
			end)
			:catch(function(e)
				maid:Destroy()
				reject(e)
			end)
	end)
end

function GameLoop:_endRound(): TypedPromise<{ Model }>
	return Promise.new(function(resolve, reject)
		if self._isEnded then
			return reject("Round already ended.")
		end

		self._isEnded = true
		self._maid:DoCleaning()

		local survivors = {} :: { string }

		for _, player in ipairs(Players:GetPlayers()) do
			if player:GetAttribute("Dead") == false then
				table.insert(survivors, player.Name)
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
			announcement.Text =
				`Survivors: {table.concat(survivors, ", ", nil, #survivors - 1)} and {survivors[#survivors]}.`
		end
		Debris:AddItem(announcement, 3)

		countdownHint.Text = "Round ended - Starting next round in 5s..."

		task.wait(5)

		self._isEnded = false

		self
			:_startRound("**") -- TODO: probably add duos or just multiple killers to survive?
			:andThen(resolve)
			:catch(reject)
	end)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function GameLoop:Begin(preferredKiller: string): TypedPromise<{ Model }>
	return self:_startRound(preferredKiller)
end

function GameLoop:Stop(): TypedPromise<{ Model }>
	return self:_endRound()
end

return GameLoop
