--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Themes = require(script.Parent.Parent.Themes)

local Children = Fusion.Children
local Peek = Fusion.peek

local ItemCard = require(script.Parent.Item)
local formatWithCommas = require(script.Parent.Format)

export type Props = {
	scope: Fusion.Scope,
	theme: Fusion.Value<Themes.ThemeSpec>,
	itemControllerNet: { [string]: RemoteFunction },
	selectedItem: Fusion.Value<string>,
	survivalsCount: Fusion.Value<number>,
	pointsCount: Fusion.Value<number>,
	purchaseStatus: Fusion.Value<string>,
	purchaseStatusColor: Fusion.Value<Color3>,
	onPurchase: () -> (),
}

return function(props: Props): Instance
	local scope = props.scope:innerScope(Fusion, OnyxUI.Util, OnyxUI.Components)
	local theme = props.theme

	local statusAlpha = scope:Value(0)
	local springStatusAlpha = scope:Spring(statusAlpha, 20, 0.9)

	local lastStatus = ""
	scope:Observer(props.purchaseStatus):onChange(function()
		local current = Peek(props.purchaseStatus)
		if current ~= lastStatus and current ~= "" then
			lastStatus = current
			statusAlpha:set(0)
			task.wait(0.05)
			statusAlpha:set(1)
		end
	end)

	local displayedSurvivals = scope:Value(Peek(props.survivalsCount))
	local displayedPoints = scope:Value(Peek(props.pointsCount))

	local survivalsSpring = scope:Spring(displayedSurvivals, 30, 0.9)
	local pointsSpring = scope:Spring(displayedPoints, 30, 0.9)

	scope:Observer(props.survivalsCount):onChange(function()
		displayedSurvivals:set(Peek(props.survivalsCount))
	end)
	scope:Observer(props.pointsCount):onChange(function()
		displayedPoints:set(Peek(props.pointsCount))
	end)

	return scope:New "Frame" {
		Name = "DetailsPanel",
		BackgroundTransparency = 0.85,
		BackgroundColor3 = scope:Computed(function(use)
			local t = use(theme)
			return use(t.Colors.Base.Dark)
		end),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),

		[Children] = {
			scope:New "UIStroke" {
				Thickness = 0.75,
				Color = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Primary.Dark)
				end),
				Transparency = 0.5,
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 8),
			},

			scope:New "Frame" {
				Name = "SurvivalsContainer",
				Size = UDim2.fromScale(0.75, 0.05),
				Position = UDim2.fromScale(0.125, 0.05),
				BackgroundColor3 = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Primary.Dark)
				end),
				BackgroundTransparency = 0.75,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0, 6),
					},
					scope:New "UIStroke" {
						Color = scope:Computed(function(use)
							local t = use(theme)
							return use(t.Colors.Primary.Main)
						end),
						Thickness = 1.5,
						Transparency = 0.3,
					},
					scope:New "TextLabel" {
						Name = "SurvivalsDisplay",
						Size = UDim2.fromScale(1, 1),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							return `🏆 Survivals: {formatWithCommas(math.round(use(survivalsSpring)))}`
						end),
						Font = Enum.Font.GothamBold,
						TextSize = scope:Computed(function(use)
							local t = use(theme)
							return use(t.TextSize["1.25"])
						end),
						TextColor3 = scope:Computed(function(use)
							local t = use(theme)
							return use(t.Colors.Primary.Main)
						end),
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
					},
				},
			},

			scope:New "Frame" {
				Name = "PointsContainer",
				Size = UDim2.fromScale(0.75, 0.05),
				Position = UDim2.fromScale(0.125, 0.125),
				BackgroundColor3 = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Secondary.Dark)
				end),
				BackgroundTransparency = 0.75,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0, 6),
					},
					scope:New "UIStroke" {
						Color = scope:Computed(function(use)
							local t = use(theme)
							return use(t.Colors.Secondary.Main)
						end),
						Thickness = 1.5,
						Transparency = 0.3,
					},
					scope:New "TextLabel" {
						Name = "PointsDisplay",
						Size = UDim2.fromScale(1, 1),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							return `💎 Points: {formatWithCommas(math.round(use(pointsSpring)))}`
						end),
						Font = Enum.Font.GothamBold,
						TextSize = scope:Computed(function(use)
							local t = use(theme)
							return use(t.TextSize["1.25"])
						end),
						TextColor3 = scope:Computed(function(use)
							local t = use(theme)
							return use(t.Colors.Secondary.Main)
						end),
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
					},
				},
			},

			scope:New "Frame" {
				Name = "SelectedItem",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.475),
				Size = UDim2.fromScale(0.9, 0.5),
				BackgroundTransparency = 1,

				[Children] = {
					scope:Computed(function(use)
						return ItemCard {
							theme = props.theme,
							itemData = props.itemControllerNet.GetItemData:InvokeServer(use(props.selectedItem)),
							scope = scope,
							onPreview = true,
						}
					end) :: any,
				},
			},

			scope:Button {
				Name = "PurchaseButton",
				Size = UDim2.fromScale(0.8, 0.1),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.775),
				Content = { "Purchase Item" },
				Style = "Filled",
				Color = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Primary.Dark)
				end),
				OnActivate = props.onPurchase,
			},

			scope:New "TextLabel" {
				Name = "PurchaseStatus",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.9),
				Size = UDim2.fromScale(0.95, 0.0725),
				BackgroundTransparency = 1,
				Text = props.purchaseStatus,
				TextColor3 = props.purchaseStatusColor,
				TextWrapped = true,
				TextScaled = true,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTransparency = scope:Computed(function(use)
					return 1 - use(springStatusAlpha)
				end),
			},
		},
	}
end
