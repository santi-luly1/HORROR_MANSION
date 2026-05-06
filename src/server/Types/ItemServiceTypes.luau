--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Maid = require("@game/ReplicatedStorage/Packages/maid")
local Promise = require("@game/ReplicatedStorage/Packages/promise")
local Signal = require("@game/ReplicatedStorage/Packages/signal")
local _SERVICE = require("@game/ServerScriptService/Server/Types/_SERVICE")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

export type ItemData = {
	Price: number,
	Name: string,
	TextureId: string,
}

export type ActiveItem = {
	Tool: Tool,
	Player: Player,
	Behavior: any,
	Maid: Maid.Maid,
}

export type ItemService = _SERVICE.SERVICE<ItemService> & {
	-- public API
	PurchaseItem: (self: ItemService, player: Player, itemName: string) -> TypedPromise<string>,
	GetItemData: (self: ItemService, itemName: string) -> ItemData?,
	HasItem: (self: ItemService, player: Player, itemName: string) -> boolean,
	IsValidItem: (self: ItemService, itemName: string) -> boolean,
	GetAvailableItems: (self: ItemService) -> { string },

	-- signals
	ItemPurchased: Signal.Signal<Player, string>,
	ItemEquipped: Signal.Signal<Player, string>,
	ItemUsed: Signal.Signal<Player, string>,

	-- private
	_activeItems: { [Tool]: ActiveItem },
	_setupTool: (self: ItemService, tool: Tool, player: Player) -> (),
	_cleanupTool: (self: ItemService, tool: Tool) -> (),
}

return (nil :: any) :: ItemService
