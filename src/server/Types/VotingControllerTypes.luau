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

export type MapData = {
	Name: string,
	Thumbnail: string,
}

export type VotingController = {
	-- lifecycle
	Init: (self: VotingController) -> (),
	Start: (self: VotingController) -> (),

	-- public API
	StartVoting: (self: VotingController, mapNames: { string }?) -> TypedPromise<string>,
	EndVoting: (self: VotingController) -> string,
	CastVote: (self: VotingController, player: Player, mapName: string) -> boolean,
	GetMapOptions: (self: VotingController) -> { MapData },
	GetWinningMap: (self: VotingController) -> string?,
	IsVoting: (self: VotingController) -> boolean,
	GetVotes: (self: VotingController) -> { [string]: number },

	-- signals
	VotingStarted: Signal.Signal<{ MapData }>,
	VotingEnded: Signal.Signal<string, { [string]: number }>,
	VoteCast: Signal.Signal<Player, string, string?>,

	-- private
	_maid: Maid.Maid,
	_init: boolean,
	_start: boolean,
	_isVoting: boolean,
	_votes: { [Player]: string },
	_mapOptions: { MapData },
	_winningMap: string,
	_countdownThread: thread?,
	_voteResolve: (winner: string) -> ()?,
}

return nil
