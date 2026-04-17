--!strict
local default = require(script.Default)

local SpecialKillerBehavior = {
	_behaviours = {},
	_default = default,
} :: SpecialKillerBehavior

type SpecialKillerBehavior = {
	Init: (self: SpecialKillerBehavior) -> (),
	Get: (self: SpecialKillerBehavior, name: string) -> BehaviorModule,

	_behaviours: { [string]: BehaviorModule },
	_default: BehaviorModule,
}

export type BehaviorModule = default.BehaviorModule

function SpecialKillerBehavior:Init()
	for _, module in ipairs(script:GetChildren()) do
		if module.Name == "Default" then
			continue
		end

		self._behaviours[module.Name] = require(module) :: BehaviorModule -- silence LLS
	end
end

function SpecialKillerBehavior:Get(name: string): BehaviorModule
	return self._behaviours[name] or self._default
end

return SpecialKillerBehavior
