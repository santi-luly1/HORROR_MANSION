--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Maid = require("@packages/maid")
local Promise = require("@packages/promise")
local Signal = require("@packages/signal")
local _SERVICE = require("@serverTypes/_SERVICE")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

export type MapData = {
	Name: string,
	Thumbnail: string,
}

export type VotingService = _SERVICE.SERVICE<VotingService> & {
	-- public API
	StartVoting: (self: VotingService, mapNames: { string }?) -> TypedPromise<string>,
	EndVoting: (self: VotingService) -> string,
	CastVote: (self: VotingService, player: Player, mapName: string) -> boolean,
	GetMapOptions: (self: VotingService) -> { MapData },
	GetWinningMap: (self: VotingService) -> string?,
	IsVoting: (self: VotingService) -> boolean,
	GetVotes: (self: VotingService) -> { [string]: number },

	-- signals
	VotingStarted: Signal.Signal<{ MapData }>,
	VotingEnded: Signal.Signal<string, { [string]: number }>,
	VoteCast: Signal.Signal<Player, string, string?>,

	-- private
	_maid: Maid.Maid,
	_isVoting: boolean,
	_votes: { [Player]: string },
	_mapOptions: { MapData },
	_winningMap: string,
	_countdownThread: thread?,
	_voteResolve: (winner: string) -> ()?,
}

return (nil :: any) :: VotingService
