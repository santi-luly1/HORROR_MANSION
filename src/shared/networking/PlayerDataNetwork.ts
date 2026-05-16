/*
[=[
	@class PlayerDataNetwork
    @author santi-luly1
    @description Networking for the PlayerDataService module.

    CHANGELOG: [
		25/12/31 --> Added SurvivalsChanged and PointsChanged items.
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
	SurvivalsChanged: Definitions.ServerToClientEvent<[newValue: number]>(),
	PointsChanged: Definitions.ServerToClientEvent<[newValue: number]>(),
});
