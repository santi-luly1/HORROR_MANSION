--[=[
    Networking for the ItemService module
	@class ItemServiceNetwork
    @author: santi-luly1

    CHANGELOG: [
		02/14/26 --> Added initial remote functions.
		02/24/26 --> Added ItemGranted item (for SpecialItemBehavior support).
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Net = require("@game/ReplicatedStorage/Packages/net")

return {
	PurchaseItem = Net:RemoteFunction("PurchaseItem"),
	GetAvailableItems = Net:RemoteFunction("GetAvailableItems"),
	GetItemData = Net:RemoteFunction("GetItemData"),
	ItemGranted = Net:RemoteEvent("ItemGranted"),
}
