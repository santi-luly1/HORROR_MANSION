/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import * as KillerServiceTypes from "./KillerServiceTypes";
import Maid from "@rbxts/maid";
import Signal from "@rbxts/signal";
import _SERVICE from "./_SERVICE";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/
export interface RoundServiceMembers {
	// public API
	Begin: (
		this: RoundServiceMembers,
		preferredKiller: string,
		skipped?: boolean,
	) => Promise<KillerServiceTypes.Killer[]>;
	Stop: (this: RoundServiceMembers, preferredKiller?: string, skipped?: boolean) => Promise<void>;
	OnIntermission: (this: RoundServiceMembers) => boolean;
	GetIntermissionTimeout: (this: RoundServiceMembers) => number;
	IsEnding: (this: RoundServiceMembers) => boolean;

	// signals
	RoundStarted: Signal;
	RoundEnded: Signal;

	// private
	_inProgress: boolean;
	_isEnding: boolean;
	_maid: Maid;

	// private methods
	_startRound: (this: RoundServiceMembers, preferredKiller: string) => Promise<KillerServiceTypes.Killer[]>;
	_endRound: (this: RoundServiceMembers, preferredKiller: string, skipped: boolean) => Promise<void>;
	_cleanupRound: (this: RoundServiceMembers, maid: Maid) => void;
	_intermissionCountdown: (this: RoundServiceMembers, skipped: boolean) => Promise<void>;
}

export type RoundServiceTypes = _SERVICE.Service<RoundServiceMembers>;

declare const _default: RoundServiceTypes;
export default _default;
