--!strict
--[=[
    Main server game loop handler
	@class GameLoop
    @author: santi-luly1

    CHANGELOG: [
		01/21/26 --> Initial version of the module.
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
} :: GameLoop

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local maid = Maid.new()
local countdownHint = Instance.new("Hint", workspace)
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
	Begin: (self: GameLoop, prefixedKiller: string?) -> TypedPromise<Model>,
	Stop: (self: GameLoop) -> TypedPromise<>,

	-- events

	-- private
	_init: boolean,
	_start: boolean,

	-- private methods
	_startRound: (self: GameLoop, prefixedKiller: string?) -> TypedPromise<Model>,
	_endRound: (self: GameLoop) -> TypedPromise<>,
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

	self:_endRound() -- start the main loop.
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function GameLoop:_startRound(prefixedKiller: string?): TypedPromise<Model>
	return Promise.new(function(resolve, reject, onCancel)
		if onCancel(function() -- I think this is wrong, since we would need to save this promise inside a variable somewhere to be able to properly cancel it.
			self:_endRound()
		end) then
			return
		end

		KillerController:SpawnKiller(prefixedKiller)
			:andThen(function(killer)
				maid:LinkToInstance(killer)

				maid:GiveTask(task.spawn(function()
					local countdown = TOTAL_ROUND_DURATION

					while task.wait(1) do
						countdownHint.Text = `{killer.Name} will leave in {countdown} seconds.`
						countdown -= 1

						if countdown < 0 then
							break
						end
					end

					self:_endRound()
				end))

				return resolve(killer)
			end)
			:catch(reject)
	end)
end

function GameLoop:_endRound(): TypedPromise<>
	return Promise.new(function(resolve, reject)
		KillerController:ClearCurrentKiller()
		print("PENDING TO DISPLAY SURVIVORS, PROPER INTERMISSION ETC.")
		countdownHint.Text = `---------------`
		task.wait(5)
		self:_startRound()
			:andThen(function(killer)
				return resolve()
			end)
			:catch(reject)
	end)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function GameLoop:Begin(preferredKiller: string?): TypedPromise<Model>
	return self:_startRound(preferredKiller)
end

function GameLoop:Stop(): TypedPromise<>
	return self:_endRound()
end

return GameLoop
