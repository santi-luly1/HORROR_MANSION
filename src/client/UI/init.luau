--!strict
--[=[
    UI manager for client
	@class UI
    @author: santi-luly1

    CHANGELOG: [
		01/01/26 --> Created module with a simple UI for survivals and points.
		01/04/26 --> Support for individual components and easier story management.
	]
]=]

--------------------------------------------------------------------
--- Components
--------------------------------------------------------------------
local PointsDisplay = require(script.PointsDisplay)
local SurvivalsDisplay = require(script.SurvivalsDisplay)

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type ComponentHandles = {
	PointsDisplay: PointsDisplay.PointsDisplayHandle?,
	SurvivalsDisplay: SurvivalsDisplay.SurvivalsDisplayHandle?,
}

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Themer = OnyxUI.Themer
local Components = OnyxUI.Components
local scoped = Fusion.scoped
local Children = Fusion.Children

local PlayerDataNet = require(Networking:WaitForChild("PlayerDataNetwork"))

local UI = {
	_init = false,
	_start = false,
	_dataConnections = {} :: { RBXScriptConnection },
	_componentHandles = {} :: ComponentHandles,
}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local playerGui = player and player:FindFirstChild("PlayerGui")

--------------------------------------------------------------------
--- ServiceBag (not currently using service bag)
--------------------------------------------------------------------
function UI:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	-- updaters
	local pointsConn = PlayerDataNet.PointsChanged.OnClientEvent:Connect(function(new: number)
		local handle = self._componentHandles.PointsDisplay
		if handle then
			handle:SetPoints(new)
		end
	end)

	local survivalsConn = PlayerDataNet.SurvivalsChanged.OnClientEvent:Connect(function(new: number)
		local handle = self._componentHandles.SurvivalsDisplay
		if handle then
			handle:SetSurvivals(new)
		end
	end)

	table.insert(self._dataConnections, pointsConn)
	table.insert(self._dataConnections, survivalsConn)
end

function UI:Start(startingTheme: OnyxUI.ThemeSpec?): (Instance, ComponentHandles?)
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	local scope = scoped(Fusion, Components)
	local Theme = startingTheme or Fusion.peek(Themer.Theme:now())

	local pointsDisplay = PointsDisplay {
		scope = scope,
		initialPoints = 0,
	}

	local survivalsDisplay = SurvivalsDisplay {
		scope = scope,
		initialSurvivals = 0,
	}

	-- store component handles for data updates
	self._componentHandles.PointsDisplay = pointsDisplay
	self._componentHandles.SurvivalsDisplay = survivalsDisplay

	if playerGui then -- we're on a server.
		return scope:New "ScreenGui" {
			Name = "UI",
			Parent = playerGui or script,
			[Children] = {
				scope:Frame { -- MainContainer
					Name = "MainContainer",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Position = UDim2.fromScale(0, 0),
					BackgroundColor3 = scope:Computed(function(use)
						return use(Theme.Colors.Base.Main)
					end), -- Using theme properly
					[Children] = {
						pointsDisplay.Component,
						survivalsDisplay.Component,
					},
				},
			},
		}
	else --we're on a storybook (maybe).
		return scope:Frame { -- MainContainer
			Name = "MainContainer",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
			BackgroundColor3 = scope:Computed(function(use)
				return use(Theme.Colors.Base.Main)
			end), -- Using theme properly
			[Children] = {
				pointsDisplay.Component,
				survivalsDisplay.Component,
			},
		},
			self._componentHandles
	end
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------

return UI
