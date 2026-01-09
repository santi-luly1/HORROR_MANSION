--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Components = OnyxUI.Components
local Themer = OnyxUI.Themer
local Children = Fusion.Children

export type PointsDisplayProps = {
	scope: Fusion.Scope,
	initialPoints: number?,
	Position: UDim2?,
	Size: UDim2?,
	ThemeColor: Color3?,
}

export type PointsDisplayHandle = {
	Component: Instance,
	SetPoints: (self: PointsDisplayHandle, newPoints: number) -> (),
	GetPoints: (self: PointsDisplayHandle) -> number,
	_pointsState: Fusion.Value<number>,
}

return function(props: PointsDisplayProps): PointsDisplayHandle
	local scope = props.scope:innerScope(Fusion, Components)
	local theme = Themer.Theme:now() -- state object

	local points = scope:Value(props.initialPoints or 0)

	local component = scope:Text {
        Name = "PointsDisplay",
		Text = scope:Computed(function(use)
			return `Points: {use(points)}`
		end),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = props.ThemeColor or theme.Colors.Primary.Main,
		AnchorPoint = Vector2.new(0, 1),
		Position = props.Position or UDim2.fromScale(0, 1),
		Size = props.Size or UDim2.fromScale(0.1, 0.045),
        [Children] = {
            scope:New "UIStroke" {}
        }
	}

	return {
		Component = component,
		SetPoints = function(_: PointsDisplayHandle, n: number)
			points:set(n)
		end,
		GetPoints = function(_: PointsDisplayHandle): number
			return Fusion.peek(points)
		end,
		_pointsState = points,
	} :: PointsDisplayHandle
end
