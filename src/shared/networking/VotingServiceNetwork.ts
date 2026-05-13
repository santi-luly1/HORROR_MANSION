/*
[=[
    Networking for the VotingService module.
	@class VotingServiceNetwork
    @author: santi-luly1

    CHANGELOG: [
		03/01/26 --> Initial networking for map voting.
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
	CastVote: Definitions.ClientToServerEvent<[mapName: string]>(),
	GetMapOptions: Definitions.ServerAsyncFunction(),
	VotingStarted: Definitions.ServerToClientEvent<[mapOptions: unknown, duration: number]>(),
	VotingEnded: Definitions.ServerToClientEvent<[mapOptions: string]>(),
	VoteUpdated: Definitions.ServerToClientEvent<[mapName: string, currentVotes: { [mapName: string]: number }]>(),
});
