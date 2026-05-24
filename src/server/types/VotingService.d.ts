/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import type Signal from "@rbxts/signal";
import { Trove } from "@rbxts/trove";

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

export default interface VotingServiceMembers {
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
