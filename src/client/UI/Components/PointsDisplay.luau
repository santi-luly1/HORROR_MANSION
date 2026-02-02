--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Components = OnyxUI.Components
local Children = Fusion.Children

export type PointsDisplayProps = {
	scope: Fusion.Scope,
	initialPoints: number?,
	Position: UDim2?,
	Size: UDim2?,
	Theme: Fusion.Value<OnyxUI.Theme>,
}

export type PointsDisplayHandle = {
	Component: Instance,
	SetPoints: (self: PointsDisplayHandle, newPoints: number) -> (),
	GetPoints: (self: PointsDisplayHandle) -> number,
}

return function(props: PointsDisplayProps): PointsDisplayHandle
	local scope = props.scope:innerScope(Fusion, Components)

	local points = scope:Value(props.initialPoints or 0)

	local component = scope:Text {
		Name = "PointsDisplay",
		Text = scope:Computed(function(use)
			return `Points: {use(points)}`
		end),
		Font = Enum.Font.GothamBold :: any, -- LLS just why are you screaming?
		TextSize = scope:Computed(function(use)
			local theme = use(props.Theme)
			return use(theme.TextSize["1.5"]) -- double call to use? should this be normal?
		end),
		TextColor3 = scope:Computed(function(use)
			local theme = use(props.Theme)
			return use(theme.Colors.Primary.Main)
		end),
		AnchorPoint = Vector2.new(0, 1),
		Position = props.Position or UDim2.fromScale(0, 1),
		Size = props.Size or UDim2.fromScale(0.1, 0.045),
		[Children] = {
			scope:New "UIStroke" {
				Thickness = scope:Computed(function(use)
					local theme = use(props.Theme)
					return use(theme.StrokeThickness["2"])
				end),
			},
		},
	}

	return {
		Component = component,
		SetPoints = function(_, n: number)
			points:set(n)
		end,
		GetPoints = function()
			return Fusion.peek(points)
		end,
	}
end
