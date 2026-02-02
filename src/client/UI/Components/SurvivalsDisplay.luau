--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

local Components = OnyxUI.Components
local Children = Fusion.Children

export type SurvivalsDisplayProps = {
	scope: Fusion.Scope,
	initialSurvivals: number?,
	Position: UDim2?,
	Size: UDim2?,
	Theme: Fusion.Value<OnyxUI.Theme>,
}

export type SurvivalsDisplayHandle = {
	Component: Instance,
	SetSurvivals: (self: SurvivalsDisplayHandle, newSurvivals: number) -> (),
	GetSurvivals: (self: SurvivalsDisplayHandle) -> number,
}

return function(props: SurvivalsDisplayProps): SurvivalsDisplayHandle
	local scope = props.scope:innerScope(Fusion, Components)

	local survivals = scope:Value(props.initialSurvivals or 0)

	local component = scope:Text {
		Name = "SurvivalsDisplay",
		Text = scope:Computed(function(use)
			return `Survivals: {use(survivals)}`
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
		Position = props.Position or UDim2.fromScale(0, 0.95),
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
		SetSurvivals = function(_, n: number)
			survivals:set(n)
		end,
		GetSurvivals = function()
			return Fusion.peek(survivals)
		end,
	}
end
