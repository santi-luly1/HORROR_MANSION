--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local KillerServiceTypes = require("@game/ServerScriptService/Server/Types/KillerServiceTypes")
local Maid = require("@game/ReplicatedStorage/Packages/maid")
local Promise = require("@game/ReplicatedStorage/Packages/promise")
local Signal = require("@game/ReplicatedStorage/Packages/signal")
local _SERVICE = require("@game/ServerScriptService/Server/Types/_SERVICE")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

export type RoundService = _SERVICE.SERVICE<RoundService> & {
	-- public API
	Begin: (
		self: RoundService,
		preferredKiller: string,
		skipped: boolean?
	) -> TypedPromise<{ KillerServiceTypes.Killer }>,
	Stop: (self: RoundService, preferredKiller: string?, skipped: boolean?) -> TypedPromise<()>,
	OnIntermission: (self: RoundService) -> boolean,
	GetIntermissionTimeout: (self: RoundService) -> number,
	IsEnding: (self: RoundService) -> boolean,

	-- signals
	RoundStarted: Signal.Signal<string>,
	RoundEnded: Signal.Signal<boolean>,

	-- private
	_inProgress: boolean,
	_isEnding: boolean,
	_maid: Maid.Maid?,

	-- private methods
	_startRound: (self: RoundService, preferredKiller: string) -> TypedPromise<{ KillerServiceTypes.Killer }>,
	_endRound: (self: RoundService, preferredKiller: string, skipped: boolean) -> TypedPromise<()>,
	_cleanupRound: (self: RoundService, maid: Maid.Maid) -> (),
	_intermissionCountdown: (self: RoundService, skipped: boolean) -> TypedPromise<()>,
}

return (nil :: any) :: RoundService
