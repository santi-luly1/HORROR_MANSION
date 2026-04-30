--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Themes = require(StarterPlayer.StarterPlayerScripts.Client.UI.Themes)
local UI = require(script.Parent.Parent.UI)

local scoped = Fusion.scoped
local Components = OnyxUI.Components

return function(Target: Instance)
	local scope = scoped(Fusion, Components)

	local isLight = scope:Value(false)

	UI:Init({})

	local uiInstance = (UI:Start() :: any) :: GuiBase -- this should be illegal.
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
		Position = UDim2.fromScale(0.9975, 0.005),
		Selection = scope:Computed(function(use)
			return use(isLight) and 0 or 1
		end),
		Scale = {
			Scale = 2,
		},
		Corner = {
			Radius = UDim.new(0, 2),
		},

		OnActivate = function()
			isLight:set(not Fusion.peek(isLight))
			UI:SetTheme(Fusion.peek(isLight) and Themes.ColdDawn or Themes.CrimsonFog)
		end,
	}

	return function()
		UI:Stop()
		scope:doCleanup()
	end
end
