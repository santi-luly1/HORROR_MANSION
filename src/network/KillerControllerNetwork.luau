--[=[
    Networking for the KillerController module.
	@class KillerControllerNetwork
    @author: santi-luly1

    CHANGELOG: [
		01/11/26 --> Added GetKillersName item.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Net = require(Packages.net)

return {
	GetKillersName = Net:RemoteFunction("GetKillersName"),
}
