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
local Packages = game:GetService("ReplicatedStorage").Packages

local Net = require(Packages.net)

return {
	RE = Net:RemoteEvent("RE"),
}
