--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Themer = OnyxUI.Themer
local scoped = Fusion.scoped
local Components = OnyxUI.Components

local UI = require(script.Parent.Parent.UI)

return function(Target: Instance)
	local scope = scoped(Fusion, Components)

	local darkTheme = Themer.Theme:now()
	local lightTheme = Themer.NewTheme(scope, {})

	local isLight = scope:Value(false)

	UI:Init()

	local uiInstance = UI:Start(scope:Computed(function(use)
		return use(isLight) and lightTheme or darkTheme -- not working rn anyways..
	end))
	uiInstance.Parent = Target

	scope:IconSwap {
		Name = script.Name,
		Parent = Target,
		Style = "Outlined",
		Color = scope:Computed(function(use)
			local colors = OnyxUI.Util.Colors
			return use(isLight) and colors.Yellow["500"] or colors.Blue["500"]
		end),
		Options = { "rbxassetid://13852158988", "rbxassetid://6035140766" },
		AnchorPoint = Vector2.new(1),
		Position = UDim2.fromScale(1, 0),
		Selection = scope:Computed(function(use)
			return use(isLight) and 0 or 1
		end),
		Scale = {
			Scale = 3,
		},
		Corner = {
			Radius = UDim.new(0, 2),
		},

		OnActivate = function()
			isLight:set(not Fusion.peek(isLight))
		end,
	}

	return function()
		UI:Stop()
		scope:doCleanup()
	end
end
