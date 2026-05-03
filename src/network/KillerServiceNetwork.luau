--[=[
    Networking for the KillerService module.
	@class KillerServiceNetwork
    @author: santi-luly1

    CHANGELOG: [
		01/11/26 --> Added GetKillersName item.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Net = require("@packages/net")

return {
	GetKillersName = Net:RemoteFunction("GetKillersName"),
}
