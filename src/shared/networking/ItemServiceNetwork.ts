/*
[=[
	@class ItemServiceNetwork
    @author santi-luly1
    @description Networking for the ItemService module

    CHANGELOG: [
		26/02/14 --> Added initial remote functions.
		26/02/24 --> Added ItemGranted item (for SpecialItemBehavior support).
		26/05/11 --> Parsed into roblox-ts.
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
	PurchaseItem: Definitions.ServerAsyncFunction<(itemName: string) => string>(),
	GetAvailableItems: Definitions.ServerAsyncFunction<() => [items: string[]]>(),
	GetItemData: Definitions.ServerAsyncFunction<(item: string) => []>(), // TODO: types
	ItemGranted: Definitions.ServerToClientEvent<[item: Tool]>(),
});
