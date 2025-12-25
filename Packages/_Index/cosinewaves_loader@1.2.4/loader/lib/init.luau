--!strict

local core = require("@self/core")
local types = require("@self/types")
local lifecycles = require("@self/lifecycles")

export type predicate<T> = types.predicate<T>
export type lifecycleModule = types.lifecycleModule
export type core = types.core
export type internal = types.internal

local loader = {
	-- core functions
	load_children = core.load_children,
	load_descendants = core.load_descendants,

	-- lifecycle functions
	register_lifecycle = lifecycles.register,
	bindSignal = lifecycles.bindSignal,
}

return loader
