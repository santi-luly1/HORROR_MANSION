/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import { Killer } from "./KillerServiceTypes";
import Signal from "@rbxts/signal";
import _SERVICE from "./_SERVICE";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/
export interface RoundServiceMembers {
	// signals
	RoundStarted: Signal<(preferredKiller: string) => void>;
	RoundEnded: Signal<(skipped: boolean) => void>;

	// public API
	Begin: (this: RoundServiceMembers, preferredKiller: string, skipped?: boolean) => Promise<Killer[] | unknown>; // replace "unknown" with something else.
	Stop: (this: RoundServiceMembers, preferredKiller?: string, skipped?: boolean) => Promise<void>;
	OnIntermission: (this: RoundServiceMembers) => boolean;
	GetIntermissionTimeout: (this: RoundServiceMembers) => number;
	IsEnding: (this: RoundServiceMembers) => boolean;
}

export type RoundServiceTypes = _SERVICE.Service<RoundServiceMembers>;

declare const _default: RoundServiceTypes;
export default _default;
