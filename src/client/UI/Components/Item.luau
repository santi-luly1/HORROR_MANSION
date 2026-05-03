--!strict
local Fusion = require("@packages/fusion")
local OnyxUI = require("@packages/onyx-ui")
local Themes = require("@client/UI/Themes")

local Children = Fusion.Children
local Peek = Fusion.peek

export type ItemCardProps = {
	scope: Fusion.Scope<any>,
	itemData: {
		Price: number,
		Name: string,
		TextureId: string,
	},
	theme: Fusion.Value<Themes.ThemeSpec>,
	onPreview: boolean?,
	onSelect: (selectedTool: string) -> ()?,
}

return function(props: ItemCardProps): Frame
	local scope = props.scope:innerScope(Fusion, OnyxUI.Util, OnyxUI.Components)
	local theme = props.theme

	local isHovered = scope:Value(false)
	local isPressed = scope:Value(false)
	local entryDelay = scope:Value(math.random() * 0.15)

	local scale = scope:Computed(function(use)
		local hover = use(isHovered)
		local pressed = use(isPressed)
		if pressed then
			return 0.95
		elseif hover then
			return 1.05
		else
			return 1
		end
	end)

	local springScale = scope:Spring(scale, 40, 0.8)

	local strokeThickness = scope:Computed(function(use)
		local hover = use(isHovered)
		local t = use(theme)
		if hover then
			return use(t.StrokeThickness["2"])
		else
			return use(t.StrokeThickness["1"])
		end
	end)

	local springStroke = scope:Spring(strokeThickness, 50, 0.9)

	local backgroundTransparency = scope:Computed(function(use)
		local hover = use(isHovered)
		if hover then
			return 0.2
		else
			return 0.5
		end
	end)

	local springBgTrans = scope:Spring(backgroundTransparency, 30, 0.95)

	local entryPosition = scope:Value(UDim2.fromScale(0.5, 0.6))
	local targetPosition = UDim2.fromScale(0.5, 0.5)
	local springPosition = scope:Spring(entryPosition, 35, 0.7)

	task.delay(Peek(entryDelay), function()
		entryPosition:set(targetPosition)
	end)

	return scope:Card {
		Name = `Card_{props.itemData.Name}`,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = springPosition,
		Size = props.onPreview and UDim2.fromScale(1, 1) or UDim2.new(1.05, 0, 0, 250),
		BackgroundTransparency = springBgTrans,
		BackgroundColor3 = scope:Computed(function(use)
			local t = use(theme)
			return use(t.Colors.Base.Light)
		end),

		Scale = {
			Scale = springScale,
		},

		Stroke = {
			Thickness = springStroke,
			Color = scope:Computed(function(use)
				local t = use(theme)
				local hover = use(isHovered)
				if hover then
					return use(t.Colors.Primary.Main)
				else
					return use(t.Colors.Base.Light)
				end
			end),
			Transparency = 0.3,
		},

		Corner = {
			Radius = scope:Computed(function(use)
				local t = use(theme)
				local value = use(t.CornerRadius.Base) :: any
				return UDim.new(0, value)
			end),
		},

		[Children] = {
			scope:Button {
				Name = "Hitbox",
				Size = UDim2.fromScale(1, 1),
				Style = "Ghost",
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
				OnActivate = function()
					if props.onSelect and not props.onPreview then
						props.onSelect(props.itemData.Name)
					end
				end,
			},

			scope:Image {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.3),
				BackgroundTransparency = 1,
				Size = scope:Computed(function(use)
					local hover = use(isHovered)
					return hover and UDim2.fromScale(0.9, 1.05) or UDim2.fromScale(0.85, 0.85)
				end),
				Image = props.itemData.TextureId,
				Aspect = {
					Ratio = 1,
				},
			},

			scope:Text {
				Name = "ItemName",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = scope:Computed(function(use)
					local hover = use(isHovered)
					return hover and UDim2.fromScale(0.5, 0.68) or UDim2.fromScale(0.5, 0.7)
				end),
				Size = UDim2.fromScale(0.95, 0.2),
				Text = props.itemData.Name,
				TextColor3 = scope:Computed(function(use)
					local t = use(theme)
					local hover = use(isHovered)

					return hover and use(t.Colors.Primary.Main) or use(t.Colors.Secondary.Main)
				end),
				TextSize = scope:Computed(function(use)
					local t = use(theme)
					local value = use(t.TextSize.Base) :: any
					return value * 1.25
				end),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				Font = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Font.Heading)
				end),
				Stroke = {
					Enabled = true,
					Thickness = scope:Computed(function(use)
						local t = use(theme)
						return use(t.StrokeThickness.Base)
					end),
					Transparency = 0,
					Color = scope:Computed(function(use)
						local t = use(theme)
						local hover = use(isHovered)

						return hover and use(t.Colors.Secondary.Main) or use(t.Colors.Primary.Main)
					end),
					LineJoinMode = Enum.LineJoinMode.Round,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				},
			},

			scope:Text {
				Name = "Price",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.88),
				Size = UDim2.fromScale(1, 0.1),
				Text = `{props.itemData.Price} Points`,
				TextColor3 = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Success.Main)
				end),
				TextSize = scope:Computed(function(use)
					local t = use(theme)
					local value = use(t.TextSize.Base) :: any
					return value * 1.25
				end),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				Font = Enum.Font.GothamBold,
			},
		},
	}
end
