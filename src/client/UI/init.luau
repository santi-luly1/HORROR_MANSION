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
		TODO: add more themes into the themes folder and make that the UI can use them (Onyx and Fusion should handle that...)
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Fusion = require(Packages:WaitForChild("fusion")) --
local Maid = require(Packages:WaitForChild("maid"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Themer = OnyxUI.Themer
local Components = OnyxUI.Components
local scoped = Fusion.scoped
local Children = Fusion.Children

local ItemControllerNet = require(Networking:WaitForChild("ItemController"))
local PlayerDataNet = require(Networking:WaitForChild("PlayerDataNetwork"))

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type FusionTheme = OnyxUI.Theme
type UI = {
	-- lifecycle
	Init: (self: UI) -> (),
	Start: (self: UI, themeState: Fusion.Computed<FusionTheme>?) -> GuiBase,
	Stop: (self: UI) -> (),
	_buildTabs: (self: UI) -> Frame,
	_buildMainContainerUI: (self: UI) -> Frame,
	_buildShopContainer: (self: UI) -> Frame,
	_buildItemsScroller: (self: UI) -> Frame,
	_buildDetailsPanel: (self: UI) -> Frame,
	_buildShopFrame: (self: UI) -> Frame,

	-- private
	_init: boolean,
	_start: boolean,
	_scope: Fusion.Scope<any>,
	_currentTheme: FusionTheme,
	_maid: Maid.Maid,
	_shopEnabled: Fusion.Value<boolean>,
	_pointsCount: Fusion.Value<number>,
	_survivalsCount: Fusion.Value<number>,
	_selectedItem: Fusion.Value<string>,

	-- private methods
	_getUIContent: (self: UI) -> Frame,
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
local ItemCard = require(script.Components.Item)

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
	self._selectedItem = self._scope:Value("Tooltip") -- a little hardcoded?

	-- updaters
	self._maid:GiveTask(PlayerDataNet.PointsChanged.OnClientEvent:Connect(function(new: number)
		self._pointsCount:set(new)
	end))

	self._maid:GiveTask(PlayerDataNet.SurvivalsChanged.OnClientEvent:Connect(function(new: number)
		self._survivalsCount:set(new)
	end))

	self._shopEnabled = self._scope:Value(true) -- false
end

function UI:Start(themeState: Fusion.Computed<FusionTheme>?): GuiBase
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	self._currentTheme = Fusion.peek(themeState) or Themer.Theme:now() -- just for the storybook, nothing else (I think)
	self._maid:GiveTask(function()
		self._scope:doCleanup()
		self._scope = nil :: any
	end)

	local playerGui = player and player:FindFirstChild("PlayerGui")

	if playerGui then -- we're on a server.
		self._maid:LinkToInstance(player)
		local screenGui = self._scope:New "ScreenGui" {
			Name = "UI",
			Parent = playerGui,
			[Children] = {
				self:_getUIContent(),
			},
		}

		return screenGui
	else --we're on a storybook (maybe).
		return self:_getUIContent()
	end
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function UI:_getUIContent(): Frame
	return self._scope:Frame { -- MainContainer
		Name = "MainContainer",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),

		[Children] = {
			self:_buildMainContainerUI(), -- TODO: pick better names bruh.
			self:_buildShopContainer(),
		},
	}
end

function UI:_buildMainContainerUI()
	return self._scope:IconButton {
		Name = "ToggleShop",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromScale(0.05, 0.1),
		Image = "",
		Color = self._scope:Computed(function(use)
			local theme = self._currentTheme
			return use(theme.Colors.Primary.Main)
		end),
		OnActivate = function()
			self._shopEnabled:set(not Fusion.peek(self._shopEnabled))
		end,
		Aspect = { Ratio = 1 },
		Scale = { Scale = 1 },
	}
end

function UI:_buildTabs()
	return self._scope:Tabs {
		Name = "Tabs",
		Size = UDim2.fromScale(0.6, 0.08),
		Position = UDim2.fromScale(0.475, 0.055),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Tabs = { { "Items" }, { "Passes" }, { "Points" } },
		SizeVariant = "ExtraLarge",
		OnHover = function(...) --FIXME: not working for some reason.
			print(...)
			print("AAAAAAAAA")
		end,
	}
end

function UI:_buildItemsScroller()
	return self._scope:Scroller {
		Name = "Items",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.715, 1),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		[Children] = self._scope:Computed(function()
			local purchasableItems = {}
			local items = ItemControllerNet.GetAvailableItems:InvokeServer() :: { string } -- return just the names
			for _, item in ipairs(items) do
				table.insert(
					purchasableItems,
					ItemCard {
						theme = self._currentTheme,
						itemData = ItemControllerNet.GetItemData:InvokeServer(item),
						scope = self._scope,
						onSelect = function(i)
							self._selectedItem:set(i)
						end,
					}
				)
			end
			table.sort(purchasableItems, function(a, b)
				return a.Name < b.Name -- sort by name
			end)
			return purchasableItems
		end),
		Stroke = {
			Color = self._scope:Computed(function(use)
				local theme = self._currentTheme
				return use(theme.Colors.Error.Main)
			end),
			Thickness = 0.75,
			Transparency = 0,
			LineJoinMode = Enum.LineJoinMode.Round,
		},
		List = {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 10),
			Wraps = true,
		},
	}
end

function UI:_buildDetailsPanel()
	return self._scope:Frame {
		Name = "DetailsPanel",
		BackgroundTransparency = 0.9,
		BackgroundColor3 = self._scope:Computed(function(use)
			local theme = self._currentTheme
			return use(theme.Colors.Base.Dark)
		end),
		Size = UDim2.fromScale(0.275, 1),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Stroke = { Thickness = 0.75 },
		[Children] = {
			-- Stats Labels
			self._scope:Text {
				Name = "SurvivalsDisplay",
				Text = self._scope:Computed(function(use)
					return `Survivals: {use(self._survivalsCount)}` -- TODO: add commas and fancy stuff? maybe?
				end),

				Font = Enum.Font.GothamBold,
				TextSize = self._scope:Computed(function(use)
					local theme = self._currentTheme
					return use(theme.TextSize["1.25"])
				end),
				TextColor3 = self._scope:Computed(function(use)
					local theme = self._currentTheme
					return use(theme.Colors.Primary.Main)
				end),
				BackgroundTransparency = 0.75,
				BackgroundColor3 = self._scope:Computed(function(use)
					local theme = self._currentTheme
					return use(theme.Colors.Primary.Dark)
				end),

				Size = UDim2.fromScale(0.75, 0.05),
				Position = UDim2.fromScale(0.125, 0.05),
				TextXAlignment = Enum.TextXAlignment.Center,

				Stroke = {
					Color = self._scope:Computed(function(use)
						local theme = self._currentTheme
						return use(theme.Colors.Primary.Dark)
					end),
					Thickness = self._scope:Computed(function(use)
						local theme = self._currentTheme
						return use(theme.StrokeThickness["2"])
					end),
					Transparency = 0,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Round,
				},
				Corner = {
					Radius = UDim.new(0, 4),
				},
			},
			self._scope:Text {
				Name = "PointsDisplay",
				Text = self._scope:Computed(function(use)
					return `Points: {use(self._pointsCount)}` -- TODO: add commas and fancy stuff? maybe?
				end),

				Font = Enum.Font.GothamBold,
				TextSize = self._scope:Computed(function(use)
					local theme = self._currentTheme
					return use(theme.TextSize["1.25"])
				end),
				TextColor3 = self._scope:Computed(function(use)
					local theme = self._currentTheme
					return use(theme.Colors.Primary.Main)
				end),
				BackgroundTransparency = 0.75,
				BackgroundColor3 = self._scope:Computed(function(use)
					local theme = self._currentTheme
					return use(theme.Colors.Primary.Dark)
				end),
				Position = UDim2.fromScale(0.125, 0.125),
				Size = UDim2.fromScale(0.75, 0.05),
				TextXAlignment = Enum.TextXAlignment.Center,

				Stroke = {
					Color = self._scope:Computed(function(use)
						local theme = self._currentTheme
						return use(theme.Colors.Primary.Dark)
					end),
					Thickness = self._scope:Computed(function(use)
						local theme = self._currentTheme
						return use(theme.StrokeThickness["2"])
					end),
					Transparency = 0,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					LineJoinMode = Enum.LineJoinMode.Round,
				},
				Corner = {
					Radius = UDim.new(0, 4),
				},
			},
			--[[self._scope:Text { --maybe?
				Text = self._scope:Computed(function(use)
					return `Streak: {0}`
				end),
				TextColor3 = self._scope:Computed(function(use)
					return use(use(self._currentTheme).Colors.Secondary.Main)
				end),
				TextSize = 14,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.15),
			},]]

			self._scope:Frame { -- Selected Item Preview
				Name = "SelectedItem",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.5),
				Stroke = { Thickness = 2 },
				[Children] = self._scope:Computed(function(use)
					return ItemCard {
						theme = self._currentTheme,
						itemData = ItemControllerNet.GetItemData:InvokeServer(use(self._selectedItem)),
						scope = self._scope,
						onPreview = true,
					}
				end),
			},

			self._scope:Button { -- Purchase Button
				Name = "PurchaseButton",
				Content = { "Purchase" },
				Size = UDim2.fromScale(0.8, 0.1),
				BackgroundColor3 = self._scope:Computed(function(use)
					local theme = self._currentTheme
					return use(theme.Colors.Success.Main)
				end),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.825),
				OnActivate = function()
					--TODO: actually display to the player the purchase status.
					local status = ItemControllerNet.PurchaseItem:InvokeServer(Fusion.peek(self._selectedItem))
					print(status)
				end,
			},
		},
	}
end

function UI:_buildShopFrame()
	return self._scope:Frame {
		Name = "Shop",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.985, 0.9),
		Position = UDim2.fromScale(0.5, 0.54),
		Stroke = {
			Color = self._scope:Computed(function(use)
				local theme = self._currentTheme
				return use(theme.Colors.Primary.Light)
			end),
			Thickness = 2.75,
			Transparency = 0,
			LineJoinMode = Enum.LineJoinMode.Round,
		},
		[Children] = {
			self:_buildItemsScroller(),
			self:_buildDetailsPanel(),
		},
	}
end

function UI:_buildShopContainer()
	local audioStatus = self._scope:Value(false) -- TODO: make the actual system, this is just a placeholder.

	return self._scope:Frame {
		Name = "ShopContainer",
		BackgroundTransparency = 0.25,
		BackgroundColor3 = self._scope:Computed(function(use)
			local theme = self._currentTheme
			return use(theme.Colors.Base.Dark)
		end),
		Size = UDim2.fromScale(0.5, 0.6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Corner = { Radius = UDim.new(0, 5) },
		Stroke = {
			Color = self._scope:Computed(function(use)
				local theme = self._currentTheme
				return use(theme.Colors.Primary.Main)
			end),
			Thickness = 2,
			Transparency = 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round,
		},
		Visible = self._scope:Computed(function(use)
			return use(self._shopEnabled)
		end),
		[Children] = {
			self._scope:IconButton {
				Name = "SoundToggle",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(0.95, 0.01),
				Size = UDim2.fromOffset(24, 24),
				Image = "rbxassetid://10814531047", -- placeholder 10814531047
				BackgroundTransparency = 1,
				Aspect = {
					Ratio = 1,
				},
				OnActivate = function()
					--TODO: make no sound work. (prob. just mute the death sounds and killer's)
					print("sound dunno.")
					audioStatus:set(not Fusion.peek(audioStatus))
				end,
			},
			self._scope:IconButton {
				Name = "CloseButton",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(0.995, 0.01),
				Size = UDim2.fromOffset(24, 24),
				Color = OnyxUI.Util.Colors.Red["500"],
				Image = "rbxassetid://13405228418", --placeholder 13405228418
				BackgroundTransparency = 1,
				Style = "Outlined",
				Aspect = {
					Ratio = 1,
				},
				OnActivate = function()
					self._shopEnabled:set(false) --TODO: anims.
				end,
			},
			self:_buildTabs(),
			self:_buildShopFrame(),
		},
	}
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
--- mainly for storybooks
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
