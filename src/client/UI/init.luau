--!strict
--[=[
    UI manager for client
	@class UI
    @author: santi-luly1

    CHANGELOG: [
		01/01/26 --> Created module with a simple UI for survivals and points.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Themer = OnyxUI.Themer

local PlayerDataNet = require(Networking:WaitForChild("PlayerDataNetwork"))
local doCleanup, scoped, peek, Children = Fusion.doCleanup, Fusion.scoped, Fusion.peek, Fusion.Children

local UI = {
	_init = false,
	_start = false,
}

local scope = scoped(Fusion, OnyxUI.Components)
local Theme = Themer.Theme:now()

local points = scope:Value(0)
local survivals = scope:Value(0)

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local playerGui = player and player:FindFirstChild("PlayerGui")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------

--------------------------------------------------------------------
--- ServiceBag (not currently using service bag)
--------------------------------------------------------------------
function UI:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	-- updaters
	PlayerDataNet.PointsChanged.OnClientEvent:Connect(function(new: number)
		points:set(new)
	end)
	PlayerDataNet.SurvivalsChanged.OnClientEvent:Connect(function(new: number)
		survivals:set(new)
	end)
end

function UI:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	-- root gui
	return scope:New "ScreenGui" {
		Name = "UI",
		Parent = playerGui or script,

		[Children] = {
			scope:New "TextLabel" { -- plain instance, zero theme deps
				Name = "totalPoints",
				BackgroundTransparency = 1,
				Font = Enum.Font.Arial,
				TextScaled = true,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.fromScale(0.1, 0.045),
				TextStrokeTransparency = 0,
				TextColor3 = Theme.Colors.Primary.Main,
				Text = scope:Computed(function(use)
					return `Points: {use(points)}`
				end),
			},
			scope:New "TextLabel" { -- Survivals label.
				Name = "totalSurvivals",
				BackgroundTransparency = 1,
				Font = Enum.Font.Arial,
				TextScaled = true,
				Size = UDim2.fromScale(0.1, 0.045),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 0.95),
				TextStrokeTransparency = 0,
				TextColor3 = Theme.Colors.Primary.Main,
				--TextColor3 = Color3.fromRGB(255, 0, 0),
				Text = scope:Computed(function(use)
					return `Survivals: {use(survivals)}`
				end),
			},
		},
	}
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------

return UI
