--!strict
--[=[
    Server-side item manager for players.
	@class ItemController
    @author: santi-luly1

    CHANGELOG: [
		02/14/26 --> Initial version of the module.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Maid = require(Packages:WaitForChild("maid"))
local Promise = require(Packages:WaitForChild("promise"))
local t = require(Packages:WaitForChild("t"))

local ItemControllerNet = require(Networking:WaitForChild("ItemController"))
local PlayerDataHandler = require(script.Parent:WaitForChild("PlayerDataHandler"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local ItemController = {
	_init = false,
	_start = false,
} :: ItemController

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local ItemsFolder = ServerStorage:WaitForChild("Items")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type TypedPromise<T...> = Promise.TypedPromise<T...>

type ItemData = {
	Price: number,
	Name: string,
	TextureId: string,
}

type ItemController = {
	-- lifecycle
	Init: (self: ItemController) -> (),
	Start: (self: ItemController) -> (),

	-- public API
	PurchaseItem: (self: ItemController, player: Player, itemName: string) -> TypedPromise<string>,
	GetItemData: (self: ItemController, itemName: string) -> ItemData?,
	HasItem: (self: ItemController, player: Player, itemName: string) -> boolean,
	IsValidItem: (self: ItemController, itemName: string) -> boolean,
	GetAvailableItems: (self: ItemController) -> { string },

	-- private
	_maid: Maid.Maid,
	_init: boolean,
	_start: boolean,
}

local purchaseCheck = t.tuple(t.instanceOf("Player"), t.string)

--------------------------------------------------------------------
--- Helpers
--------------------------------------------------------------------
local function getItemData(itemName: string): ItemData?
	local item = ItemsFolder:FindFirstChild(itemName)
	if not item then
		return nil
	end

	return {
		Name = item.Name,
		Price = item:GetAttribute("Price") or 0,
		TextureId = item.TextureId ~= "" and item.TextureId or "rbxassetid://13239978994", -- PLACE HOLDER ID
	}
end

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function ItemController:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	self._maid = Maid.new()

	-- handle client requests
	ItemControllerNet.PurchaseItem.OnServerInvoke = function(player: Player, itemName: string)
		local status -- so uglyyyyyyyyy ughhhhhhhhhhhhhh
		if not RunService:IsRunning() then -- we're on a story (maybe?).
			return `Successfully purchased {itemName}`
		end

		self:PurchaseItem(player, itemName)
			:andThen(function(info: string)
				status = info
			end)
			:catch(function(e)
				status = e
			end):await()

		return status
	end

	ItemControllerNet.GetAvailableItems.OnServerInvoke = function()
		return self:GetAvailableItems()
	end

	ItemControllerNet.GetItemData.OnServerInvoke = function(_, itemName: string)
		local data = self:GetItemData(itemName)
		return data or nil
	end
end

function ItemController:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function ItemController:PurchaseItem(player: Player, itemName: string): TypedPromise<string>
	return Promise.new(function(resolve, reject, onCancel)
		local maid = Maid.new()

		if onCancel(function()
			maid:Destroy()
		end) then
			return
		end

		local ok, err = purchaseCheck(player, itemName)
		if not ok then
			return reject(`[{script.Name}] {err}`)
		end

		-- Validate
		local itemData = getItemData(itemName)
		if not itemData then
			return reject("Item does not exist")
		end

		if self:HasItem(player, itemName) then
			return reject("Item already bought")
		end

		local points --why do I have to make it like this? so ugly
		PlayerDataHandler:GetPlayerData(player)
			:andThen(function(data)
				points = data.Points
			end)
			:await() -- await or else this will be skipped (oopsie)
		if points < itemData.Price then
			return reject("Insufficient points")
		end

		PlayerDataHandler:UpdatePlayerStat(player, "Points", -itemData.Price)
			:andThen(function()
				local tool: Tool = ItemsFolder[itemData.Name]:Clone()
				tool.Parent = player.StarterGear
				tool:Clone().Parent = player.Backpack -- so the player gets the item instantely instead of having to reset.
				maid:LinkToInstance(tool)
				self._maid:GiveTask(maid)
				return resolve(`Successfully purchased {itemName}`)
			end)
			:catch(reject)
	end)
end

function ItemController:GetItemData(itemName: string): ItemData?
	return getItemData(itemName)
end

function ItemController:HasItem(player: Player, itemName: string): boolean
	return player.StarterGear:FindFirstChild(itemName) ~= nil
end

function ItemController:IsValidItem(itemName: string): boolean
	return getItemData(itemName) ~= nil
end

function ItemController:GetAvailableItems(): { string }
	local names = {}
	for _, item in ipairs(ItemsFolder:GetChildren()) do
		table.insert(names, item.Name)
	end
	return names
end

return ItemController
