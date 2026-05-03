--[=[
    Networking for the VotingService module.
	@class VotingServiceNetwork
    @author: santi-luly1

    CHANGELOG: [
		03/01/26 --> Initial networking for map voting.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Net = require("@packages/net")

return {
	CastVote = Net:RemoteFunction("CastVote"),
	GetMapOptions = Net:RemoteFunction("GetMapOptions"),
	GetVotes = Net:RemoteFunction("GetVotes"),

	-- to client
	VotingStarted = Net:RemoteEvent("VotingStarted"),
	VotingEnded = Net:RemoteEvent("VotingEnded"),
	VoteUpdated = Net:RemoteEvent("VoteUpdated"),
}
