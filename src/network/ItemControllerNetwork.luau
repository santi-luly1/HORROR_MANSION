--[=[
    Networking for the ItemController module
	@class ItemControllerNetwork
    @author: santi-luly1

    CHANGELOG: [
		02/14/26 --> Added initial remote functions.
		02/24/26 --> Added ItemGranted item (for SpecialItemBehavior support).
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
	ItemGranted = Net:RemoteEvent("ItemGranted"),
}
