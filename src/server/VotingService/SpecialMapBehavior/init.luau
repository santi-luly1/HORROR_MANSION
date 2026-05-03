--!strict
local Default = require("@self/Default")

local SpecialMapBehavior = {
	_behaviours = {},
	_default = Default,
} :: SpecialMapBehavior

type SpecialMapBehavior = {
	Init: (self: SpecialMapBehavior) -> (),
	Get: (self: SpecialMapBehavior, name: string) -> BehaviorModule,

	_behaviours: { [string]: BehaviorModule },
	_default: BehaviorModule,
}

export type BehaviorModule = Default.BehaviorModule

function SpecialMapBehavior:Init()
	for _, module in ipairs(script:GetChildren()) do
		if module.Name == "Default" then
			continue
		end

		self._behaviours[module.Name] = require(module) :: BehaviorModule
	end
end

function SpecialMapBehavior:Get(name: string): BehaviorModule
	return self._behaviours[name] or self._default
end

return SpecialMapBehavior
