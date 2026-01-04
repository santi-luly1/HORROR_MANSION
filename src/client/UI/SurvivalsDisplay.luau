--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Components = OnyxUI.Components
local Themer = OnyxUI.Themer

export type SurvivalsDisplayProps = {
	scope: Fusion.Scope,
	initialSurvivals: number?,
	Position: UDim2?,
	Size: UDim2?,
	ThemeColor: Color3?,
}

export type SurvivalsDisplayHandle = {
	Component: Instance,
	SetSurvivals: (self: SurvivalsDisplayHandle, newSurvivals: number) -> (),
	GetSurvivals: (self: SurvivalsDisplayHandle) -> number,
	_survivalsState: Fusion.Value<number>,
}

return function(props: SurvivalsDisplayProps): SurvivalsDisplayHandle
	local scope = props.scope:innerScope(Fusion, Components)
	local Theme = Themer.Theme:now()

	local survivals = scope:Value(props.initialSurvivals or 0)

	local component = scope:Text {
        Name = "SurvivalsDisplay",
		Text = scope:Computed(function(use)
			return `Survivals: {use(survivals)}`
		end),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = props.ThemeColor or Theme.Colors.Primary.Main,
		AnchorPoint = Vector2.new(0, 1),
		Position = props.Position or UDim2.fromScale(0, 0.95),
		Size = props.Size or UDim2.fromScale(0.1, 0.045),
	}

	return {
		Component = component,
		SetSurvivals = function(_: SurvivalsDisplayHandle, newSurvivals: number)
			survivals:set(newSurvivals)
		end,
		GetSurvivals = function(_: SurvivalsDisplayHandle): number
			return Fusion.peek(survivals)
		end,
		_survivalsState = survivals,
	} :: SurvivalsDisplayHandle
end
