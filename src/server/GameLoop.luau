--!strict
--[=[
    Main server game loop handler
	@class GameLoop
    @author: santi-luly1

    CHANGELOG: [
		01/21/26 --> Initial version of the module.
		01/28/26 --> Adjusted to the new KillerController and added checks for in-progress rounds.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Maid = require(Packages.maid)
local Promise = require(Packages:WaitForChild("promise"))

local KillerController = require(script.Parent.KillerController)

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
		maid:GiveTask(function()
			self._inProgress = false
			KillerController:Clear()
		end)
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
				and KillerController:SpawnKillers(killersToSpawn, 1)
			or KillerController:SpawnAll(1)

		spawnPromise
			:andThen(function(killers)
				if cancelled then
					return
				end

				if #killers == 0 then
					maid:Destroy()
					return reject("No killers spawned")
				end

				for _, killer in ipairs(killers) do
					maid:LinkToInstance(killer)
				end

				maid:GiveTask(task.spawn(function()
					local countdown = TOTAL_ROUND_DURATION

					while countdown >= 0 do
						if #killers > 1 then
							countdownHint.Text = `{#killers} killers leave in {countdown}s`
						else
							countdownHint.Text = `{killers[1].Name} leaves in {countdown}s`
						end

						task.wait(1)
						countdown -= 1
					end

					task.defer(function()
						self:_endRound()
					end)
				end))

				resolve(killers)
			end)
			:catch(function(e)
				maid:Destroy()
				reject(e)
			end)
	end)
end

function GameLoop:_endRound(): TypedPromise<{ Model }>
	return Promise.new(function(resolve, reject)
		self._maid:DoCleaning()
		print("PENDING TO DISPLAY SURVIVORS, PROPER INTERMISSION ETC.")
		countdownHint.Text = "Round ended - Starting next round in 5s..."

		task.wait(5)

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
