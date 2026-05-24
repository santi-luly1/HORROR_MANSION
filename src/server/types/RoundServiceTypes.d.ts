/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import { Killer } from "./KillerServiceTypes";
import Signal from "@rbxts/signal";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/
export default interface RoundServiceMembers {
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
