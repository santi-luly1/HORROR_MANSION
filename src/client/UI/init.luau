--!strict
--[=[
    UI manager for client
	@class UI
    @author: santi-luly1

    CHANGELOG: [
		01/01/26 --> Created module with a simple UI for survivals and points.
		01/04/26 --> Support for individual components and easier story management.
        01/31/26 --> Added reactive theme support for UI Labs integration.
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

local Fusion = require(Packages:WaitForChild("fusion"))
local Maid = require(Packages:WaitForChild("maid"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Themer = OnyxUI.Themer
local Components = OnyxUI.Components
local scoped = Fusion.scoped
local Children = Fusion.Children

local PlayerDataNet = require(Networking:WaitForChild("PlayerDataNetwork"))

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type ComponentHandles = {
	PointsDisplay: any,
	SurvivalsDisplay: any,
}
type FusionTheme = Fusion.Value<OnyxUI.Theme>
type UI = {
	-- lifecycle
	Init: (self: UI) -> (),
	Start: (self: UI, themeState: FusionTheme?) -> GuiBase,
	Stop: (self: UI) -> (),

	-- private
	_init: boolean,
	_start: boolean,
	_scope: Fusion.Scope<any>,
	_dataConnections: { RBXScriptConnection },
	_componentHandles: ComponentHandles,
	_currentTheme: FusionTheme,
	_maid: Maid.Maid,

	-- private methods
	_createComponents: (self: UI, theme: FusionTheme) -> ComponentHandles,
	_getUIContent: (self: UI, themeState: FusionTheme) -> Frame,
}

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local UI = {
	_init = false,
	_start = false,
	_dataConnections = {},
} :: UI

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local player = Players.LocalPlayer
local PointsDisplayModule = require(script.Components.PointsDisplay)
local SurvivalsDisplayModule = require(script.Components.SurvivalsDisplay)

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function UI:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	self._scope = scoped(Fusion, Components)
	self._maid = Maid.new()

	-- updaters
	local pointsConn = PlayerDataNet.PointsChanged.OnClientEvent:Connect(function(new: number)
		local handle = self._componentHandles and self._componentHandles.PointsDisplay
		if handle then
			handle:SetPoints(new)
		end
	end)

	local survivalsConn = PlayerDataNet.SurvivalsChanged.OnClientEvent:Connect(function(new: number)
		local handle = self._componentHandles and self._componentHandles.SurvivalsDisplay
		if handle then
			handle:SetSurvivals(new)
		end
	end)

	table.insert(self._dataConnections, pointsConn)
	table.insert(self._dataConnections, survivalsConn)
end

function UI:Start(themeState: FusionTheme?): GuiBase
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	self._currentTheme = themeState or self._scope:Value(Themer.Theme:now()) -- just for the storybook, nothing else (I think)
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
				self:_getUIContent(self._currentTheme),
			},
		}

		return screenGui
	else --we're on a storybook (maybe).
		return self:_getUIContent(self._currentTheme)
	end
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function UI:_createComponents(theme: FusionTheme): ComponentHandles
	assert(self._scope, "UI not initialized")

	return {
		PointsDisplay = PointsDisplayModule {
			scope = self._scope,
			initialPoints = 0,
			Theme = theme,
		},
		SurvivalsDisplay = SurvivalsDisplayModule {
			scope = self._scope,
			initialSurvivals = 0,
			Theme = theme,
		},
	}
end

function UI:_getUIContent(themeState: FusionTheme): Frame
	return self._scope:Frame { -- MainContainer
		Name = "MainContainer",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),

		[Children] = self._scope:Computed(function()
			self._componentHandles = self:_createComponents(themeState)

			return {
				self._componentHandles.PointsDisplay.Component,
				self._componentHandles.SurvivalsDisplay.Component,
			}
		end),
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

	for _, conn in ipairs(self._dataConnections) do
		conn:Disconnect()
	end
	self._dataConnections = {}

	self._maid:DoCleaning()

	self._componentHandles = nil :: any
	self._currentTheme = nil :: any
	self._start = false
	self._init = false
end

return UI
