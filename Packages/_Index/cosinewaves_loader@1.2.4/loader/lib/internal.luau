--!strict

local types = require("./types")
local promise = require("./promise")
local lifecycles = require("./lifecycles")

local LOGGING_ENABLED: boolean = false
local DEFAULT_PRIORITY: number = 1

local startedPromises: { [string]: any } = {}

--[=[
	@class internal

	The `internal` class contains core utility functions, configurations, and lifecycle mechanisms
	used internally by the loader. These include safe module requiring with lifecycle
	method execution (`init`, `start`), environment setting overrides, module tracking, and dependency
	waiting.
]=]
local internal = {} :: types.internal

--[=[
	Waits for the specified module to finish its `start` lifecycle before continuing.

	Returns a promise that resolves when the target module has completed starting,
	allowing dependent modules to sequence their initialization using methods like `:andThen()`.

	@within internal
	@param name string -- the name of the module to wait for
	@return any -- a resolving or rejecting promise based on module availability
]=]
internal.waitFor = function(name: string): any
	local startPromise: any = startedPromises[name]
	if startPromise :: any then
		return startPromise :: any
	else
		warn("(loader::internal)", `waitFor called for unknown module: {name}`)
		return promise.reject(`no module named {name} has been loaded yet`) :: any
	end
end

--[=[
	Safely requires a module and executes its lifecycle methods (`init` and `start`).

	If the module exports `init`, it is invoked immediately.
	If it exports `start`, a start promise is created and tracked.
	Also injects `waitFor` into the module so it can depend on others.

	@within internal
	@param module ModuleScript -- the module to require and initialize
	@return any -- a promise resolving to the required module
]=]
internal.safeRequire = function(module: ModuleScript): any
	local moduleName = module.Name
	return promise.new(function(resolve, reject)
		local ok, result = pcall(require, module)
		if not ok then
			warn("(loader::internal)", `failed to require {moduleName}: {result}`)
			return reject(result)
		end

		warn("(loader::internal)", `required module: {moduleName}`)
		local mod = result :: types.lifecycleModule

		-- add waitFor
		local _promises = lifecycles.connect(moduleName, mod, internal.waitFor)

		-- resolve once module is required; start happens asynchronously inside lifecycles.connect
		resolve(mod)
	end)
end

--[=[
	Returns the priority of a given module script, checking if it has the "priority" key and returning it.

	@within internal
	@param module ModuleScript -- the module to check
	@return number
]=]
internal.get_priority = function(module: ModuleScript): number
	local ok, mod = pcall(require, module)
	if ok and typeof(mod) == "table" then
		local pr = rawget(mod, "priority")
		if typeof(pr) == "number" then
			return pr
		end
	end
	return DEFAULT_PRIORITY -- default priority when none provided or require fails
end

--[=[
	Loads and initializes modules from a specified container, optionally including descendants,
	and filters them using an optional predicate.

	Each module is safely required, its lifecycle methods invoked, and start promises tracked.
	Returns a promise that resolves after all modules and their start routines complete.

	The priority of each module is accounted for, with an optional key inside the module tabled,
	called "Priority". Higher priority number will mean that the module is loaded and started before other's
	with less priority.

	@within internal
	@param container Instance -- the Roblox instance containing modules to load
	@param useDescendants boolean -- whether to include all descendants (true) or only direct children (false)
	@param predicate predicate<Instance>? -- optional filter function to select modules
	@return any -- a promise resolving to true if all modules loaded successfully, false otherwise
]=]
internal.load_modules = function(
	container: Instance,
	useDescendants: boolean,
	predicate: types.predicate<Instance>?
): any
	local containerName: string = container.Name
	print(
		`(loader::internal) {if useDescendants then "loading descendants" else "loading children"} in {containerName}`
	)

	local t0: number = os.clock()
	local instances: { Instance } = if useDescendants then container:GetDescendants() else container:GetChildren()
	local filtered: { ModuleScript } = {}

	for _, inst in ipairs(instances) do
		if inst:IsA("ModuleScript") and (not predicate or predicate(inst)) then
			table.insert(filtered, inst)
		end
	end

	-- Sort modules by declared priority (higher number = higher priority)
	table.sort(filtered, function(a: ModuleScript, b: ModuleScript): boolean
		return internal.get_priority(a) > internal.get_priority(b)
	end)

	print(`(loader::internal) sorted modules by priority (highest first)`)
	local moduleCount = #filtered
	local promises = {}

	for _, moduleScript in ipairs(filtered) do
		table.insert(promises, internal.safeRequire(moduleScript))
	end

	return promise
		.all(promises)
		:andThen(function()
			-- Wait only for modules that define a "start" lifecycle
			local waitStartPromises = {}
			for _, moduleScript in ipairs(filtered) do
				local name = moduleScript.Name
				local success, mod = pcall(require, moduleScript)
				if success and typeof(mod) == "table" and rawget(mod, "start") and typeof(mod.start) == "function" then
					table.insert(waitStartPromises, lifecycles.waitFor(name, "start"))
				end
			end
			return promise.all(waitStartPromises)
		end)
		:andThen(function()
			if LOGGING_ENABLED :: boolean then
				local elapsed = (os.clock() - t0) * 1000
				print(
					`(loader::internal) successfully loaded {moduleCount} modules in {string.format("%.2f", elapsed)}ms`
				)
			end
			return true
		end)
		:catch(function(err)
			warn(`(loader::internal) failed to load one or more modules from {containerName}: {err}`)
			return false
		end)
end

return internal
