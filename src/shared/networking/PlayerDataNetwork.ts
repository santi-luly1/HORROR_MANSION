/*
[=[
    Networking for the PlayerDataService module.
	@class PlayerDataNetwork
    @author: santi-luly1

    CHANGELOG: [
		12/31/25 --> Added SurvivalsChanged and PointsChanged items.
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
	SurvivalsChanged: Definitions.ServerToClientEvent<[newValue: number]>(),
	PointsChanged: Definitions.ServerToClientEvent<[newValue: number]>(),
});
