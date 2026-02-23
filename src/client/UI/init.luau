--!strict
--[=[
    UI manager for client
	@class UI
    @author: santi-luly1

    CHANGELOG: [
		01/01/26 --> Created module with a simple UI for survivals and points.
		01/04/26 --> Support for individual components and easier story management.
        01/31/26 --> Added reactive theme support for UI Labs integration.
		02/14/26 --> Initial UI major stage (points shop).
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Fusion = require(Packages:WaitForChild("fusion"))
local Maid = require(Packages:WaitForChild("maid"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Components = OnyxUI.Components
local scoped = Fusion.scoped
local Children = Fusion.Children

local ItemControllerNet = require(Networking:WaitForChild("ItemController"))
local PlayerDataNet = require(Networking:WaitForChild("PlayerDataNetwork"))
local UIThemes = require(script:WaitForChild("Themes"))

local ShopContainer = require(script.Components.ShopContainer)
local ShopFrame = require(script.Components.ShopFrame)
local ShopToggleButton = require(script.Components.ShopToggleButton)
local Themes = require(script.Themes)

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type FusionTheme = OnyxUI.Theme
type PurchaseStatusTone = "idle" | "pending" | "success" | "error"

type UI = {
	-- lifecycle
	Init: (self: UI) -> (),
	Start: (self: UI) -> GuiBase,
	Stop: (self: UI) -> (),
	SetTheme: (self: UI, theme: FusionTheme) -> (),
	SetThemeByName: (self: UI, themeName: string) -> boolean,

	-- private
	_init: boolean,
	_start: boolean,
	_scope: Fusion.Scope<any>,
	_currentTheme: FusionTheme,
	_maid: Maid.Maid,
	_shopEnabled: Fusion.Value<boolean>,
	_purchaseStatus: Fusion.Value<string>,
	_purchaseStatusColor: Fusion.Value<Color3>,
	_activeTab: Fusion.Value<number>,
	_pointsCount: Fusion.Value<number>,
	_survivalsCount: Fusion.Value<number>,
	_selectedItem: Fusion.Value<string>,

	-- private methods
	_buildContent: (self: UI) -> Frame,
	_onSelectItem: (self: UI, itemName: string) -> (),
	_handlePurchase: (self: UI) -> (),
}

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local UI = {
	_init = false,
	_start = false,
} :: UI

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local player = Players.LocalPlayer

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function UI:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	self._scope = scoped(Fusion, Components)
	self._maid = Maid.new()
	self._pointsCount = self._scope:Value(0)
	self._survivalsCount = self._scope:Value(0)
	self._selectedItem = self._scope:Value("Tooltip")
	self._activeTab = self._scope:Value(1)
	self._purchaseStatus = self._scope:Value("")
	self._purchaseStatusColor = self._scope:Value(Color3.fromRGB(255, 255, 255))
	self._shopEnabled = self._scope:Value(true)
	self._currentTheme = self._scope:Value(nil)

	self._maid:GiveTask(PlayerDataNet.PointsChanged.OnClientEvent:Connect(function(new: number)
		self._pointsCount:set(new)
	end))

	self._maid:GiveTask(PlayerDataNet.SurvivalsChanged.OnClientEvent:Connect(function(new: number)
		self._survivalsCount:set(new)
	end))
end

function UI:Start(): GuiBase
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	self:SetTheme(Themes.ColdDawn)
	self._maid:GiveTask(function()
		self._scope:doCleanup()
		self._scope = nil :: any
	end)

	local playerGui = player and player:FindFirstChild("PlayerGui")

	if playerGui then
		self._maid:LinkToInstance(player)
		local screenGui = self._scope:New "ScreenGui" {
			Name = "UI",
			Parent = playerGui,
			[Children] = {
				self:_buildContent(),
			},
		}

		return screenGui
	else
		return self:_buildContent()
	end
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function UI:_onSelectItem(itemName: string)
	self._selectedItem:set(itemName)
	self._purchaseStatus:set("")
	self._purchaseStatusColor:set(Fusion.peek(Fusion.peek(self._currentTheme).Colors.Primary.Main))
end

function UI:_handlePurchase()
	self._purchaseStatus:set("Purchasing...")
	self._purchaseStatusColor:set(Fusion.peek(Fusion.peek(self._currentTheme).Colors.Primary.Main))

	local status = ItemControllerNet.PurchaseItem:InvokeServer(Fusion.peek(self._selectedItem))
	local text = tostring(status)
	self._purchaseStatus:set(text)

	if string.find(string.lower(text), "success", 1, true) then
		self._purchaseStatusColor:set(Fusion.peek(Fusion.peek(self._currentTheme).Colors.Success.Main))
	else
		self._purchaseStatusColor:set(Fusion.peek(Fusion.peek(self._currentTheme).Colors.Error.Main))
	end
end

function UI:_buildContent(): Frame
	local shopFrame = ShopFrame {
		scope = self._scope,
		theme = self._currentTheme,
		itemControllerNet = ItemControllerNet,
		selectedItem = self._selectedItem,
		survivalsCount = self._survivalsCount,
		pointsCount = self._pointsCount,
		purchaseStatus = self._purchaseStatus,
		purchaseStatusColor = self._purchaseStatusColor,
		onSelect = function(itemName: string)
			self:_onSelectItem(itemName)
		end,
		onPurchase = function()
			self:_handlePurchase()
		end,
	}

	return self._scope:Frame {
		Name = "MainContainer",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),

		[Children] = {
			ShopToggleButton {
				scope = self._scope,
				theme = self._currentTheme,
				shopEnabled = self._shopEnabled,
				onToggle = function()
					self._shopEnabled:set(not Fusion.peek(self._shopEnabled))
				end,
			},
			ShopContainer {
				scope = self._scope,
				theme = self._currentTheme,
				visible = self._shopEnabled,
				onClose = function()
					self._shopEnabled:set(false)
				end,
				onSoundToggle = function()
					print("MAKE AUDIO WORK")
				end,
				shopFrameElement = shopFrame,
			},
		},
	}
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function UI:SetTheme(theme: FusionTheme)
	self._currentTheme:set(theme)
end

function UI:SetThemeByName(themeName: string): boolean
	local theme = UIThemes[themeName]
	if not theme then
		return false
	end

	self:SetTheme(theme)
	return true
end

function UI:Stop()
	if not self._start then
		return
	end

	self._maid:Destroy()
	self._maid:DoCleaning()

	self._currentTheme = nil :: any
	self._start = false
	self._init = false
end

return UI
