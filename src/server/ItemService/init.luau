--!strict
--[=[
	@class ItemService
    @author santi-luly1
    @description Server-side item manager for players.

    CHANGELOG: [
		02/14/26 --> Initial version of the module.
		02/24/26 --> Added SpecialItemBehavior support (smth like SpecialKillerBehavior).
		02/25/26 --> Auto-purchase flashlight on join.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
-- Roblox services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Packages
local Maid = require("@packages/maid")
local Promise = require("@packages/promise")
local Signal = require("@packages/signal")
local t = require("@packages/t")

-- Types
local PlayerDataServiceTypes = require("@serverTypes/PlayerDataServiceTypes")
local Types = require("@serverTypes/ItemServiceTypes")

-- Networking
local Netwoking = require("@network/ItemServiceNetwork")

-- Local utilities
local SpecialItemBehavior = require("@server/ItemService/SpecialItemBehavior")

-- Services
local PlayerDataService: PlayerDataServiceTypes.PlayerDataService

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local ItemService = {
	_init = false,
	_start = false,
	_activeItems = {},
} :: Types.ItemService
ItemService.Dependencies = { "PlayerDataService" }

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local ItemsFolder = ServerStorage:WaitForChild("Items")

local purchaseCheck = t.tuple(t.instanceOf("Player"), t.string)

--------------------------------------------------------------------
--- Helpers
--------------------------------------------------------------------
local function getItemData(itemName: string): Types.ItemData?
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
function ItemService:Init(registry)
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	PlayerDataService = registry.PlayerDataService

	self.ItemPurchased = Signal.new()
	self.ItemEquipped = Signal.new()
	self.ItemUsed = Signal.new()

	SpecialItemBehavior:Init()

	workspace.DescendantAdded:Connect(function(descendant) -- dodgy?????????????? nah
		if not descendant:IsA("Tool") then
			return
		end

		local tool: Tool = descendant
		local player = Players:GetPlayerFromCharacter(tool.Parent)
		if player then
			self:_setupTool(tool, player)
		end
	end)

	Netwoking.PurchaseItem.OnServerInvoke = function(player: Player, itemName: string)
		if not RunService:IsRunning() then -- we're on a story (maybe?).
			return `Successfully purchased {itemName}`
		end

		local status -- so uglyyyyyyyyy ughhhhhhhhhhhhhh
		self:PurchaseItem(player, itemName)
			:andThen(function(info: string)
				status = info
			end)
			:catch(function(e)
				status = e
			end)
			:await()

		return status
	end

	Netwoking.GetAvailableItems.OnServerInvoke = function()
		return self:GetAvailableItems()
	end

	Netwoking.GetItemData.OnServerInvoke = function(_, itemName: string)
		local data = self:GetItemData(itemName)
		return data or nil
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		for tool, data in pairs(self._activeItems) do
			if data.Player == player then
				self:_cleanupTool(tool)
			end
		end
	end)
end

function ItemService:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	Players.PlayerAdded:Connect(function(player: Player)
		PlayerDataService.ProfileLoaded:Once(function(plr: Player)
			if plr ~= player then
				return
			end

			self:PurchaseItem(player, "Flashlight"):catch(warn) -- starter flashlight
		end)
	end)
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------
function ItemService:_setupTool(tool: Tool, player: Player)
	local itemData = getItemData(tool.Name)
	if not itemData then
		return
	end

	if self._activeItems[tool] then
		return
	end

	local maid = Maid.new()
	local behavior = SpecialItemBehavior:Get(tool.Name)

	xpcall(function()
		behavior(tool, player, maid)
	end, function(e)
		warn(`{tool.Name}'s behavior has encoutered an error:\n{e}`)
	end)

	local activeItem: Types.ActiveItem = {
		Tool = tool,
		Player = player,
		Behavior = behavior,
		Maid = maid,
	}

	self._activeItems[tool] = activeItem

	maid:GiveTask(tool.AncestryChanged:Connect(function()
		if
			not tool:IsDescendantOf(workspace)
			and not tool:IsDescendantOf(player.Backpack)
			and not tool:IsDescendantOf(player.StarterGear)
			and not tool:IsDescendantOf(player.Character :: Model) -- silence LLS
		then
			self:_cleanupTool(tool)
		end
	end))

	Netwoking.ItemGranted:FireClient(player, tool) -- re-fire, since the client has already cleared its connections, so it need to remake them.
	self.ItemEquipped:Fire(player, tool.Name)
end

function ItemService:_cleanupTool(tool: Tool)
	local activeItem = self._activeItems[tool]
	if not activeItem then
		return
	end

	activeItem.Maid:Destroy()
	self._activeItems[tool] = nil
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function ItemService:PurchaseItem(player: Player, itemName: string): Types.TypedPromise<string>
	return Promise.new(function(resolve, reject, onCancel)
		if onCancel(function() end) then
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

		local _, points: number = PlayerDataService:GetPlayerData(player)
			:andThen(function(data)
				return data.Points
			end)
			:await() -- await or else this will be skipped (oopsie)

		if points < itemData.Price then
			return reject("Insufficient points")
		end

		PlayerDataService:UpdatePlayerStat(player, "Points", -itemData.Price)
			:andThen(function()
				local tool: Tool = ItemsFolder[itemData.Name]:Clone()
				tool.Parent = player.StarterGear

				local backpackTool = tool:Clone()
				backpackTool.Parent = player.Backpack -- so the player gets the item instantely instead of having to reset.

				--self:_setupTool(backpackTool, player) -- nope, this should be automatically handled by ChildAdded event inside Init

				Netwoking.ItemGranted:FireClient(player, backpackTool)

				return resolve(`Successfully purchased {itemName}`)
			end)
			:catch(reject)
	end)
end

function ItemService:GetItemData(itemName: string): Types.ItemData?
	return getItemData(itemName)
end

function ItemService:HasItem(player: Player, itemName: string): boolean
	return player.StarterGear:FindFirstChild(itemName) ~= nil
end

function ItemService:IsValidItem(itemName: string): boolean
	return getItemData(itemName) ~= nil
end

function ItemService:GetAvailableItems(): { string }
	local names = {}
	for _, item in ipairs(ItemsFolder:GetChildren()) do
		table.insert(names, item.Name)
	end
	return names
end

return ItemService
