/*
[=[
    Boilerplate for networking stuff
	@class _BOILERPLATE_Network
    @author: author

    CHANGELOG: [
		MM/DD/YY --> change
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
	Template: Definitions.ServerToClientEvent<[]>(),
});
