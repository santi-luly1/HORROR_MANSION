--[=[
    Boilerplate for networking stuff
	@class _BOILERPLATE_Network
    @author: santi-luly1

    CHANGELOG: [
		MM/DD/YY --> change
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Net = require("@game/ReplicatedStorage/Packages/net")

return {
	RE = Net:RemoteEvent("RE"),
}
