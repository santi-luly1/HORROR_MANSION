--!strict
local Fusion = require("@game/ReplicatedStorage/Packages/fusion")
local OnyxUI = require("@game/ReplicatedStorage/Packages/onyx-ui")
local Themes = require("@game/StarterPlayer/StarterPlayerScripts/Client/UI/Themes")

local Children = Fusion.Children
local Peek = Fusion.peek

export type Props = {
	scope: Fusion.Scope<any>,
	theme: Fusion.Value<Themes.ThemeSpec>,
	visible: Fusion.Value<boolean>,
	onClose: () -> (),
	onSoundToggle: () -> (),
	shopFrameElement: Frame,
}

return function(props: Props): Frame
	local scope = props.scope:innerScope(Fusion, OnyxUI.Util, OnyxUI.Components)
	local theme = props.theme

	local targetScale = scope:Value(0.8)
	local targetTransparency = scope:Value(1)
	local targetPosition = scope:Value(UDim2.fromScale(0.5, 0.6))

	local springScale = scope:Spring(targetScale, 35, 0.75)
	local springTransparency = scope:Spring(targetTransparency, 25, 0.9)
	local springPosition = scope:Spring(targetPosition, 35, 0.75)

	scope:Observer(props.visible):onChange(function()
		local isVisible = Peek(props.visible)
		if isVisible then
			targetScale:set(1.0)
			targetTransparency:set(0.25)
			targetPosition:set(UDim2.fromScale(0.5, 0.5))
		else
			targetScale:set(0.8)
			targetTransparency:set(1)
			targetPosition:set(UDim2.fromScale(0.5, 0.6))
		end
	end)

	if Peek(props.visible) then
		targetScale:set(1.0)
		targetTransparency:set(0.25)
		targetPosition:set(UDim2.fromScale(0.5, 0.5))
	end

	return scope:New "Frame" {
		Name = "ShopContainer",
		BackgroundTransparency = springTransparency,
		BackgroundColor3 = scope:Computed(function(use)
			local t = use(theme)
			return use(t.Colors.Base.Dark)
		end),
		Size = UDim2.fromScale(0.5, 0.6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = springPosition,
		Visible = scope:Computed(function(use)
			return use(springTransparency) < 0.99
		end),

		[Children] = {
			scope:New "UIScale" {
				Scale = springScale,
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 12),
			},

			scope:New "UIStroke" {
				Color = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Primary.Main)
				end),
				Thickness = scope:Spring(
					scope:Computed(function(use)
						local visible = use(props.visible)
						return visible and 3 or 1
					end),
					40,
					0.8
				),
				Transparency = scope:Computed(function(use)
					return (use(springTransparency) :: number) * 0.5
				end),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Round,
			},

			scope:New "Frame" {
				Name = "Backdrop",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 0.5,
				BackgroundColor3 = Color3.new(0, 0, 0),
				ZIndex = -1,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0, 12),
					},
				},
			},

			scope:New "Frame" {
				Name = "TopbarContainer",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.fromScale(1, 0.08),
				BackgroundTransparency = 0.5,
				BackgroundColor3 = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Primary.Dark)
				end),

				[Children] = {
					scope:IconButton { --- SOUND
						Name = "SoundToggle",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(0.945, 0.5),
						Size = UDim2.fromOffset(32, 32),
						Color = OnyxUI.Util.Colors.Red["500"],
						Image = "rbxassetid://10814531047",
						Style = "Outlined",
						OnActivate = props.onSoundToggle,
					},

					scope:IconButton { --- CLOSE
						Name = "CloseButton",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(0.99, 0.5),
						Size = UDim2.fromOffset(32, 32),
						Color = OnyxUI.Util.Colors.Red["500"],
						Image = "rbxassetid://13405228418",
						Style = "Outlined",
						OnActivate = props.onClose,
					},

					scope:Heading {
						Name = "Title",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromScale(0.5, 0.7),
						Position = UDim2.fromScale(0.5, 0.5),
						Text = "Item Shop",
						TextColor3 = scope:Computed(function(use)
							local t = use(theme)
							return use(t.Colors.Secondary.Main)
						end),
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						Font = scope:Computed(function(use)
							local t = use(theme)
							return use(t.Font.Heading)
						end),

						[Children] = {
							scope:New "UIStroke" {
								Color = scope:Computed(function(use)
									local t = use(theme)
									return use(t.Colors.Primary.Light)
								end),
								Thickness = 1,
								Transparency = 0.3,
								ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
								LineJoinMode = Enum.LineJoinMode.Round,
							},
						},
					},
				},
			},

			props.shopFrameElement,
		},
	}
end
