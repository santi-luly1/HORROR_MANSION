--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Themes = require(StarterPlayer.StarterPlayerScripts.Client.UI.Themes)

local Components = OnyxUI.Components
local Children = Fusion.Children

export type MapData = {
	Name: string,
	Thumbnail: string,
}

export type Props = {
	scope: Fusion.Scope,
	theme: Fusion.Value<Themes.ThemeSpec>,
	visible: Fusion.Value<boolean>,
	mapOptions: Fusion.Value<{ MapData }>,
	votes: Fusion.Value<{ [string]: number }>,
	timer: Fusion.Value<number>,
	winner: Fusion.Value<string?>,
	onVote: (mapName: string) -> (),
	onClose: () -> (),
}

return function(props: Props): Frame -- TODO: anims
	local scope = props.scope:innerScope(Fusion, Components)
	local theme = props.theme

	local function createMapButton(mapData: MapData)
		local voteCount = scope:Computed(function(use)
			local currentVotes = use(props.votes)
			return currentVotes[mapData.Name] or 0
		end)

		local isWinner = scope:Computed(function(use)
			local win = use(props.winner)
			return win == mapData.Name
		end)

		return scope:New "Frame" {
			Name = mapData.Name,
			Size = UDim2.fromScale(0.3, 0.5),
			BackgroundColor3 = scope:Computed(function(use)
				local t = use(theme)
				local winner = use(isWinner)
				if winner then
					return use(t.Colors.Success.Dark)
				end
				return use(t.Colors.Base.Dark)
			end),

			[Children] = {
				scope:New "UICorner" {
					CornerRadius = UDim.new(0, 8),
				},
				scope:New "ImageButton" {
					Name = "Thumbnail",
					Size = UDim2.new(1, -20, 0, 150),
					Position = UDim2.fromOffset(10, 10),
					BackgroundColor3 = scope:Computed(function(use)
						local t = use(theme)
						return use(t.Colors.Base.Main)
					end),
					Image = mapData.Thumbnail,
					[Fusion.OnEvent("Activated")] = function()
						props.onVote(mapData.Name)
					end,
					[Children] = {
						scope:New "UICorner" {
							CornerRadius = UDim.new(0, 6),
						},
					},
				},
				scope:Text {
					Name = "MapName",
					Size = UDim2.fromScale(1, 0.05),
					Position = UDim2.fromOffset(10, 170),
					BackgroundTransparency = 1,
					Text = mapData.Name,
					TextColor3 = scope:Computed(function(use)
						local t = use(theme)
						return use(t.Colors.Primary.Main)
					end),
					Font = Enum.Font.GothamBold :: any,
					TextSize = 20,
				},
				scope:Text {
					Name = "VoteCount",
					Size = UDim2.new(1, -20, 0, 30),
					Position = UDim2.fromOffset(10, 210),
					BackgroundTransparency = 1,
					Text = scope:Computed(function(use)
						local count = use(voteCount)
						return `{count} vote{count == 1 and "" or "s"}`
					end),
					TextColor3 = scope:Computed(function(use)
						local t = use(theme)
						return use(t.Colors.Neutral.Main)
					end),
					Font = Enum.Font.Gotham :: any,
					TextSize = 16,
				},
			},
		}
	end

	local mapButtonsContainer = scope:New "Frame" {
		Name = "MapButtonsContainer",
		Size = UDim2.new(1, -40, 1, -110),
		Position = UDim2.fromOffset(20, 100),
		BackgroundTransparency = 1,
		Visible = scope:Computed(function(use)
			return use(props.winner) == nil
		end),
		[Children] = {
			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 20),
			},
		},
	}

	scope:Observer(props.mapOptions):onChange(function()
		for _, child in ipairs(mapButtonsContainer:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end

		local options = Fusion.peek(props.mapOptions)
		for _, mapData in ipairs(options) do
			local button = createMapButton(mapData)
			button.Parent = mapButtonsContainer
		end
	end)

	return scope:New "Frame" {
		Name = "MapVotingFrame",
		Visible = props.visible,
		BackgroundColor3 = scope:Computed(function(use)
			local t = use(theme)
			return use(t.Colors.Base.Dark)
		end),
		BackgroundTransparency = 0.1,
		Size = UDim2.fromScale(0.6, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),

		[Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 12),
			},
			scope:New "TextLabel" {
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 50),
				AnchorPoint = Vector2.new(0.5),
				Position = UDim2.fromScale(0.5, 0),
				BackgroundTransparency = 1,
				Text = "VOTE FOR NEXT MAP",
				TextColor3 = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Primary.Main)
				end),
				Font = Enum.Font.GothamBold,
				TextSize = 28,
			},
			scope:New "TextLabel" {
				Name = "Timer",
				Size = UDim2.new(1, 0, 0, 30),
				AnchorPoint = Vector2.new(0.5),
				Position = UDim2.fromScale(0.5, 0.075),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return `{use(props.timer)}s`
				end),
				TextColor3 = scope:Computed(function(use)
					local t = use(theme)
					return use(t.Colors.Warning.Main)
				end),
				Font = Enum.Font.GothamBold,
				TextSize = 24,
			},
			scope:Frame {
				Name = "WinnerDisplay",
				Size = UDim2.fromScale(1, 0.6),
				Position = UDim2.fromScale(0, 0.4),
				BackgroundTransparency = 1,
				Visible = scope:Computed(function(use)
					return use(props.winner) ~= nil
				end),
				[Children] = {
					scope:Text {
						Name = "WinnerText",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							local win = use(props.winner)
							return win and `WINNER:\n{win}` or ""
						end),
						TextColor3 = scope:Computed(function(use)
							local t = use(theme)
							return use(t.Colors.Success.Main)
						end),
						Font = Enum.Font.GothamBold :: any,
						TextSize = 32,
					},
				},
			},
			mapButtonsContainer,
		},
	} :: Frame
end
