/*
[=[
	@class KillerServiceNetwork
    @author santi-luly1
    @description Networking for the KillerService module.

    CHANGELOG: [
		26/01/11 --> Added GetKillersName item.
		26/05/11 --> Parsed into roblox-ts.
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
	GetKillersName: Definitions.ServerAsyncFunction<() => [names: string[]]>(),
});
