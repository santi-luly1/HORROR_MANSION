--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Themes = require(script.Parent.Parent.Themes)

local Children = Fusion.Children

local DetailsPanel = require(script.Parent.DetailsPanel)
local ItemsScroller = require(script.Parent.ItemsScroller)

export type Props = {
	scope: Fusion.Scope<any>,
	theme: Fusion.Value<Themes.ThemeSpec>,
	itemControllerNet: { [string]: RemoteFunction },
	selectedItem: Fusion.Value<string>,
	survivalsCount: Fusion.Value<number>,
	pointsCount: Fusion.Value<number>,
	purchaseStatus: Fusion.Value<string>,
	purchaseStatusColor: Fusion.Value<Color3>,
	onSelect: (itemName: string) -> (),
	onPurchase: () -> (),
}

return function(props: Props): Frame
	local scope = props.scope:innerScope(Fusion, OnyxUI.Util, OnyxUI.Components)
	local theme = props.theme

	local contentAlpha = scope:Value(0)
	local springContentAlpha = scope:Spring(contentAlpha, 25, 0.9)

	task.delay(0.2, function()
		contentAlpha:set(1)
	end)

	return scope:Frame {
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.985, 0.88),
		Position = UDim2.fromScale(0.5, 0.545),
		BackgroundTransparency = 1,

		Stroke = {
			Color = scope:Computed(function(use)
				local t = use(theme)
				return use(t.Colors.Secondary.Dark)
			end),
			Thickness = scope:Spring(
				scope:Computed(function(use)
					local alpha = use(springContentAlpha)
					return 0.75 * alpha
				end),
				30, 0.9
			),
			Transparency = scope:Computed(function(use)
				return 1 - use(springContentAlpha)
			end),
			LineJoinMode = Enum.LineJoinMode.Round,
		},

		[Children] = {
			scope:New "Frame" {
				Name = "ItemsSection",
				Size = UDim2.fromScale(0.715, 1),
				BackgroundTransparency = 1,
				ClipsDescendants = true,

				[Children] = {
					ItemsScroller {
						scope = scope,
						theme = theme,
						itemControllerNet = props.itemControllerNet,
						onSelect = props.onSelect,
					},
				},
			},

			scope:New "Frame" {
				Name = "DetailsSection",
				Size = UDim2.fromScale(0.285, 1),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				BackgroundTransparency = 1,

				[Children] = {
					DetailsPanel {
						scope = scope,
						theme = theme,
						itemControllerNet = props.itemControllerNet,
						selectedItem = props.selectedItem,
						survivalsCount = props.survivalsCount,
						pointsCount = props.pointsCount,
						purchaseStatus = props.purchaseStatus,
						purchaseStatusColor = props.purchaseStatusColor,
						onPurchase = props.onPurchase,
					},
				},
			},
		},
	}
end