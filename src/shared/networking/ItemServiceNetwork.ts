/*
[=[
    Networking for the ItemService module
	@class ItemServiceNetwork
    @author: santi-luly1

    CHANGELOG: [
		02/14/26 --> Added initial remote functions.
		02/24/26 --> Added ItemGranted item (for SpecialItemBehavior support).
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
	PurchaseItem: Definitions.ClientToServerEvent<[itemName: string]>(),
	GetAvailableItems: Definitions.ServerAsyncFunction<() => [string]>(),
	GetItemData: Definitions.ServerAsyncFunction<(item: string) => []>(), // TODO: types
	ItemGranted: Definitions.ServerToClientEvent<[item: Tool]>(),
});
