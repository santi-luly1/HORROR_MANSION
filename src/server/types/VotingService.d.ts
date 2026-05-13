/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import type Signal from "@rbxts/signal";
import { Trove } from "@rbxts/trove";
import type _SERVICE from "server/types/_SERVICE";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/

export interface MapData {
	Name: string;
	Thumbnail: string;
}

export interface BehaviorModule {
	OnMapLoaded: (this: BehaviorModule, mapModel: Model, trove: Trove) => void;
}

export declare class SpecialMapBehaviorType {
	Init: (this: SpecialMapBehaviorType) => void;
	Get: (this: SpecialMapBehaviorType, name: string) => BehaviorModule;

	// private
	private _default: BehaviorModule;
	private _behaviors: Record<string, BehaviorModule>;
}

export interface VotingServiceMembers {
	// private
	_isVoting: boolean;
	_votes: Record<string, string> | undefined;
	_mapOptions: MapData[];
	_winningMap: string;
	_trove: Trove;
	_voteResolve: ((winner: string) => void) | undefined;
	_countdownThread: thread;

	// signals
	VotingStarted: Signal;
	VotingEnded: Signal;
	VoteCast: Signal;

	// public API
	StartVoting(this: VotingServiceMembers, mapNames?: string[] | undefined): Promise<string>;
	EndVoting(this: VotingServiceMembers): string;
	CastVote(this: VotingServiceMembers, player: Player, mapName: string): boolean;
	GetMapOptions(this: VotingServiceMembers): Array<MapData>;
	GetWinningMap(this: VotingServiceMembers): string;
	IsVoting(this: VotingServiceMembers): boolean;
	GetVotes(this: VotingServiceMembers): Record<string, number>;
}

export type VotingServiceTypes = _SERVICE.Service<VotingServiceMembers>;

declare const _default: VotingServiceTypes;
export default _default;
