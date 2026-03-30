--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Maid = require(Packages.maid)
local Promise = require(Packages:WaitForChild("promise"))
local Signal = require(Packages:WaitForChild("signal"))
local _SERVICE = require(script.Parent._SERVICE)

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

export type ItemController = _SERVICE.SERVICE<ItemController> & {
	-- public API
	PurchaseItem: (self: ItemController, player: Player, itemName: string) -> TypedPromise<string>,
	GetItemData: (self: ItemController, itemName: string) -> ItemData?,
	HasItem: (self: ItemController, player: Player, itemName: string) -> boolean,
	IsValidItem: (self: ItemController, itemName: string) -> boolean,
	GetAvailableItems: (self: ItemController) -> { string },

	-- signals
	ItemPurchased: Signal.Signal<Player, string>,
	ItemEquipped: Signal.Signal<Player, string>,
	ItemUsed: Signal.Signal<Player, string>,

	-- private
	_activeItems: { [Tool]: ActiveItem },
	_setupTool: (self: ItemController, tool: Tool, player: Player) -> (),
	_cleanupTool: (self: ItemController, tool: Tool) -> (),
}

return (nil :: any) :: ItemController
