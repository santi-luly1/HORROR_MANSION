--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Themes = require(script.Parent.Parent.Themes)

local Children = Fusion.Children

export type Props = {
	scope: Fusion.Scope<any>,
	theme: Fusion.Value<Themes.ThemeSpec>,
	shopEnabled: Fusion.Value<boolean>,
	onToggle: () -> (),
}

return function(props: Props): Frame
	local scope = props.scope:innerScope(Fusion, OnyxUI.Util, OnyxUI.Components)
	local theme = props.theme

	local isHovered = scope:Value(false)
	local isPressed = scope:Value(false)

	local targetScale = scope:Computed(function(use)
		local pressed = use(isPressed)
		local hovered = use(isHovered)
		if pressed then
			return 0.85
		elseif hovered then
			return 1.15
		else
			return 1.0
		end
	end)

	local springScale = scope:Spring(targetScale, 45, 0.7)

	local targetRotation = scope:Computed(function(use)
		local enabled = use(props.shopEnabled)
		if enabled then
			return 15
		else
			return 0
		end
	end)

	local targetColor = scope:Computed(function(use)
		local t = use(theme)
		local hovered = use(isHovered)
		if hovered then
			return use(t.Colors.Primary.Light) or use(t.Colors.Primary.Main)
		else
			return use(t.Colors.Primary.Main)
		end
	end)
	local springColor = scope:Spring(targetColor, 40, 0.9)

	return scope:Frame {
		Name = "ToggleShopContainer",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.9975, 0.995),
		Size = UDim2.fromOffset(64, 64),
		BackgroundTransparency = 1,

		[Children] = {
			scope:New "UIScale" {
				Scale = scope:Computed(function(use)
					return use(springScale)
				end),
			},

			scope:IconButton {
				Name = "ToggleShop",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Image = "rbxassetid://13852158988",
				Color = springColor,
				Rotation = scope:Spring(targetRotation, 30, 0.8),
				Style = "Outlined",

				Stroke = {
					Color = springColor,
					Thickness = scope:Computed(function(use)
						return use(isHovered) and 3 or 2
					end),
					Transparency = 0.2,
				},

				OnHover = function()
					isHovered:set(true)
				end,
				OnHoverEnd = function()
					isHovered:set(false)
					isPressed:set(false)
				end,
				OnHold = function()
					isPressed:set(true)
				end,
				OnHoldEnd = function()
					isPressed:set(false)
				end,
				OnActivate = props.onToggle,
			},
		},
	}
end
