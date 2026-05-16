/*
[=[
	@class _BOILERPLATE_Network
    @author author
    @description Boilerplate for networking stuff

    CHANGELOG: [
		yy/mm/dd --> change
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
