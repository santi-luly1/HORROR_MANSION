--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Maid = require(Packages.maid)
local Promise = require(Packages:WaitForChild("promise"))
local Signal = require(Packages:WaitForChild("signal"))

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

export type RoundController = {
	-- lifecycle
	Init: (self: RoundController) -> (),
	Start: (self: RoundController) -> (),

	-- public API
	Begin: (self: RoundController, preferredKiller: string, skipped: boolean?) -> TypedPromise<{ Model }>,
	Stop: (self: RoundController, preferredKiller: string?, skipped: boolean?) -> TypedPromise<()>,
	OnIntermission: (self: RoundController) -> boolean,
	GetIntermissionTimeout: (self: RoundController) -> number,
	IsEnding: (self: RoundController) -> boolean,

	-- signals
	RoundStarted: Signal.Signal<string>,
	RoundEnded: Signal.Signal<boolean>,

	-- private
	_init: boolean,
	_start: boolean,
	_inProgress: boolean,
	_isEnding: boolean,
	_maid: Maid.Maid?,

	-- private methods
	_startRound: (self: RoundController, preferredKiller: string) -> TypedPromise<{ Model }>,
	_endRound: (self: RoundController, preferredKiller: string, skipped: boolean) -> TypedPromise<()>,
	_cleanupRound: (self: RoundController, maid: Maid.Maid) -> (),
	_intermissionCountdown: (self: RoundController, skipped: boolean) -> TypedPromise<()>,
}

return nil
