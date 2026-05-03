--!strict
local KillerServiceTypes = require("@serverTypes/KillerServiceTypes")
local default = require("@self/Default")

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

export type BehaviorModule = KillerServiceTypes.BehaviorModule

function SpecialKillerBehavior:Init()
	for _, module in ipairs(script:GetChildren()) do
		if module.Name == "Default" then
			continue
		end

		local m = require(module) :: BehaviorModule
		m.__index = m
		setmetatable(m, { __index = self._default })

		self._behaviours[module.Name] = (m :: any) :: BehaviorModule -- silence LLS
	end
end

function SpecialKillerBehavior:Get(name: string): BehaviorModule
	return self._behaviours[name] or self._default
end

return SpecialKillerBehavior
