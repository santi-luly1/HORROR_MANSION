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

	local uiInstance = UI:Start((scope:Computed(function(use)
		return use(isLight) and lightTheme or darkTheme
	end) :: any) :: Fusion.Value<OnyxUI.Theme>)
	uiInstance.Parent = Target

	scope:IconButton {
		Parent = Target,
		Position = UDim2.fromScale(0.5, 0.1),
		Size = UDim2.fromOffset(40, 40),
		Image = scope:Computed(function(use)
			return use(isLight) and "rbxassetid://6035140766" -- sun
				or "rbxassetid://6035067836" -- moon
		end),
		Color = scope:Computed(function(use)
			return use(isLight) and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 255)
		end),
		OnActivate = function()
			isLight:set(not Fusion.peek(isLight))
		end,
	}

	return function()
		UI:Stop()
		scope:doCleanup()
	end
end
