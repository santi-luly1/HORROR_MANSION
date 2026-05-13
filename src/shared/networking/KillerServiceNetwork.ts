/*
[=[
    Networking for the KillerService module.
	@class KillerServiceNetwork
    @author: santi-luly1

    CHANGELOG: [
		01/11/26 --> Added GetKillersName item.
		05/11/26 --> Parsed into roblox-ts.
	]
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import Net, { Definitions } from "@rbxts/net";

export = Net.CreateDefinitions({
	GetKillersName: Definitions.ServerAsyncFunction<() => [string]>(),
});
