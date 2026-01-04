--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Themer = OnyxUI.Themer
local scoped = Fusion.scoped
local Components = OnyxUI.Components

local uiModule = require(script.Parent.Parent.UI)

return function(Target: Instance)
	local scope = scoped(Fusion, Components)
	local Theme = Themer.Theme:now()

	local useLight = scope:Value(false)
	local activeTheme = scope:Computed(function(use)
		return use(useLight) and Themer.NewTheme(scope, {}) -- empty = default light
			or Themer.Theme:now() -- default dark
	end)

	-- Mount UI under the chosen theme
	Themer.Theme:is(Fusion.peek(activeTheme)):during(function()
		-- Create the actual UI
		local uiInstance = uiModule:Start()
		uiInstance.Parent = Target

		return function() -- will this even work? We're in a contextual block...
			if uiInstance and uiInstance.Parent then
				uiInstance:Destroy()
			end
		end
	end)

	-- Quick toggle button using OnyxUI components
	scope:IconButton {
		Image = "rbxassetid://6035140766", -- icon
		Parent = Target,
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		ImageColor3 = Theme.Colors.Neutral.Main,
		OnActivate = function()
			print("AAAAAAAAAAAAAAAA")
			useLight:set(not Fusion.peek(useLight))
		end,
	}

	return function()
		Target:Destroy()
	end
end
