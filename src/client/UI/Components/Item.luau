--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Components = OnyxUI.Components
local Children = Fusion.Children

export type ItemCardProps = {
	scope: Fusion.Scope,
	itemData: {
		Price: number,
		Name: string,
		TextureId: string,
	},
	theme: OnyxUI.Theme,
	onPreview: boolean?, -- I should come up with better names, but just to verify the right size (if on the items list or the preview frame)
	onSelect: (selectedTool: string) -> ()?,
}

return function(props: ItemCardProps): Frame
	local scope = props.scope:innerScope(Fusion, Components)

	local component = scope:Card {
		Name = `Card_{props.itemData.Name}`,
		AnchorPoint = Vector2.new(0.5, 0.5), -- they're managed by the scrolling frame anyways, so no issue I guess.
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.onPreview and UDim2.fromScale(1, 1) or UDim2.new(0.55, 0, 0, 250),
		BackgroundTransparency = 0.5,
		BackgroundColor3 = scope:Computed(function(use)
			local theme = props.theme
			return use(theme.Colors.Base.Light)
		end),
		Stroke = {
			Thickness = scope:Computed(function(use)
				local theme = props.theme
				return use(theme.StrokeThickness["1"])
			end),
			Color = scope:Computed(function(use)
				local theme = props.theme
				return use(theme.Colors.Base.Light)
			end),
			Transparency = 0.5,
		},

		[Children] = {
			scope:Button { -- select hitbox (forgot abt it)
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = scope:Computed(function(use)
					local theme = props.theme
					return use(theme.Colors.Base.Light)
				end),
				OnActivate = function()
					if props.onSelect and not props.onPreview then
						props.onSelect(props.itemData.Name)
					end
				end,
			},
			-- Item Image
			scope:Image {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.85, 1),
				Position = UDim2.fromScale(0.5, 0.3),
				Image = props.itemData.TextureId, -- already has a default fallback
				BackgroundTransparency = 1,
				Aspect = {
					Ratio = 1,
				},
			},

			-- Item Name
			scope:Text {
				Name = "ItemName",
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromScale(1, 0.15),
				Position = UDim2.fromScale(0, 0.7),
				Text = props.itemData.Name,
				TextColor3 = scope:Computed(function(use)
					local theme = props.theme
					return use(theme.Colors.Secondary.Main)
				end),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Center :: any,
				Font = Enum.Font.GothamBold :: any,
			},

			-- Price
			scope:Text {
				Name = "Price",
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromScale(1, 0.1),
				Position = UDim2.fromScale(0, 0.9),
				Text = `{props.itemData.Price} Points`,
				TextColor3 = scope:Computed(function(use)
					local theme = props.theme
					return use(theme.Colors.Success.Main)
				end),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Center :: any,
				Font = Enum.Font.Gotham :: any,
			},
		},
	}

	return component
end
