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
local Net = require("@packages/net")

return {
	RE = Net:RemoteEvent("RE"),
}
