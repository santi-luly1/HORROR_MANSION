--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Themes = require(StarterPlayer.StarterPlayerScripts.Client.UI.Themes)

local Children = Fusion.Children

local ItemCard = require(script.Parent.Item)

export type Props = {
	scope: Fusion.Scope<any>,
	theme: Fusion.Value<Themes.ThemeSpec>,
	itemControllerNet: { [string]: RemoteFunction },
	onSelect: (itemName: string) -> (),
}

return function(props: Props): Frame
	local scope = props.scope:innerScope(Fusion, OnyxUI.Util, OnyxUI.Components)
	local theme = props.theme

	return scope:Scroller {
		Name = "Items",
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0, 0),
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromScale(0, 0),

		Stroke = {
			Color = scope:Computed(function(use)
				local t = use(theme)
				return use(t.Colors.Primary.Light)
			end),
			Thickness = 0.75,
			Transparency = 0.5,
			LineJoinMode = Enum.LineJoinMode.Round,
		},

		List = {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 12),
			Wraps = true,
		},

		Padding = {
			All = UDim.new(0, 10),
		},

		[Children] = scope:Computed(function()
			local purchasableItems = {}
			local items = props.itemControllerNet.GetAvailableItems:InvokeServer() :: { string }

			for _, item in ipairs(items) do
				table.insert(
					purchasableItems,
					ItemCard {
						theme = theme,
						itemData = props.itemControllerNet.GetItemData:InvokeServer(item),
						scope = scope,
						onSelect = props.onSelect,
					}
				)
			end

			table.sort(purchasableItems, function(a, b)
				return a.Name < b.Name
			end)

			return purchasableItems
		end),
	}
end
