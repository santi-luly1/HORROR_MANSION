--!strict
------------------------------------------------------------------------------ Please nerf all gears inside this game, as for now, all of them can basically one-shot the killers.
local default = require(script.Default)

local SpecialItemBehavior = {
	_behaviours = {},
	_default = default,
} :: SpecialItemBehavior

type SpecialItemBehavior = {
	Init: (self: SpecialItemBehavior) -> (),
	Get: (self: SpecialItemBehavior, name: string) -> BehaviorModule,

	_behaviours: { [string]: BehaviorModule },
	_default: BehaviorModule,
}

export type BehaviorModule = default.BehaviorModule

function SpecialItemBehavior:Init()
	for _, module in ipairs(script:GetChildren()) do
		if module.Name == "Default" then
			continue
		end

		self._behaviours[module.Name] = require(module) :: BehaviorModule
	end
end

function SpecialItemBehavior:Get(name: string): BehaviorModule
	return self._behaviours[name] or self._default
end

return SpecialItemBehavior
