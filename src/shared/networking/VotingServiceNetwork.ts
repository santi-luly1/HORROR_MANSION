/*
[=[
	@class VotingServiceNetwork
    @author santi-luly1
    @description Networking for the VotingService module.

    CHANGELOG: [
		26/03/01 --> Initial networking for map voting.
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
	CastVote: Definitions.ClientToServerEvent<[mapName: string]>(),
	GetMapOptions: Definitions.ServerAsyncFunction(),
	VotingStarted: Definitions.ServerToClientEvent<[mapOptions: unknown, duration: number]>(), // "mapOptions" should be MapData[], but dunno how to bring it here rn.
	VotingEnded: Definitions.ServerToClientEvent<[mapOptions: unknown]>(),
	VoteUpdated: Definitions.ServerToClientEvent<[mapName: string, currentVotes: Map<string, number>]>(),
});
