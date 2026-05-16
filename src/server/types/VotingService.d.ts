/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import type Signal from "@rbxts/signal";
import { Trove } from "@rbxts/trove";
import type _SERVICE from "./_SERVICE";

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

export interface SpecialMapBehaviorType {
	Init: (this: SpecialMapBehaviorType) => void;
	Get: (this: SpecialMapBehaviorType, name: string) => BehaviorModule;
}

export interface VotingServiceMembers {
	// signals
	VotingStarted: Signal<(mapOptions: MapData[]) => void>;
	VotingEnded: Signal<(winner: string, voteCount: Map<string, number>) => void>;
	VoteCast: Signal<(player: Player, mapName: string, previousVote: string) => void>;

	// public API
	StartVoting(this: VotingServiceMembers, mapNames?: string[]): Promise<string>;
	EndVoting(this: VotingServiceMembers): string;
	CastVote(this: VotingServiceMembers, player: Player, mapName: string): boolean;
	GetMapOptions(this: VotingServiceMembers): Array<MapData>;
	GetWinningMap(this: VotingServiceMembers): string;
	IsVoting(this: VotingServiceMembers): boolean;
	GetVotes(this: VotingServiceMembers): Map<string, number>;
}

export type VotingServiceTypes = _SERVICE.Service<VotingServiceMembers>;

declare const _default: VotingServiceTypes;
export default _default;
