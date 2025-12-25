--!strict

local internal = require("./internal")
local types = require("./types")

--[=[
	@class loader

	a lightweight, lifecycle-aware & promise-based module loader for roblox. designed for modular architecture, dependency safety, and async initialisation.
]=]
local loader = {} :: types.core

--[=[
	Loads child modules of a given container, applying an optional filter predicate.

	@within loader
	@param container Instance -- the container whose children modules to load
	@param predicate predicate<Instance>? -- optional filter to select which modules to load
	@return any -- a promise resolving when all modules and their starts complete
]=]
loader.load_children = function(container: Instance, predicate: types.predicate<Instance>?): any
	return internal.load_modules(container, false, predicate) :: any
end

--[=[
	Loads descendant modules of a given container, applying an optional filter predicate.

	@within loader
	@param container Instance -- the container whose descendant modules to load
	@param predicate predicate<Instance>? -- optional filter to select which modules to load
	@return any -- a promise resolving when all modules and their starts complete
]=]
loader.load_descendants = function(container: Instance, predicate: types.predicate<Instance>?): any
	return internal.load_modules(container, true, predicate) :: any
end

return loader
