--[=[
    Networking for the ItemController module
	@class ItemController
    @author: santi-luly1

    CHANGELOG: [
		02/14/26 --> Added initial remote functions.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Net = require(Packages.net)

return {
	PurchaseItem = Net:RemoteFunction("PurchaseItem"),
	GetAvailableItems = Net:RemoteFunction("GetAvailableItems"),
	GetItemData = Net:RemoteFunction("GetItemData"),
}
