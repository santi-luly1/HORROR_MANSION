--!strict
--[=[
	@class Controllers
    @description Controllers registry

    CHANGELOG: [
		03/01/26 --> Initial version of the module.
		03/30/26 --> Dependency graph (ai refactor).
	]
]=]

local Promise = require("@game/ReplicatedStorage/Packages/promise")

export type ControllerRegistry = {
	CmdrClient: typeof(require("@game/StarterPlayer/StarterPlayerScripts/Client/Types/CmdrClientTypes")),
	ItemController: typeof(require("@game/StarterPlayer/StarterPlayerScripts/Client/Types/ItemControllerTypes")),
	UI: typeof(require("@game/StarterPlayer/StarterPlayerScripts/Client/Types/UITypes")),
}

local Controllers = {}
local registry = {} :: ControllerRegistry

function Controllers.Register<T>(name: string, controller: T)
	assert(not registry[name], `Controller '{name}' already registered`)
	registry[name] = controller
end

local function buildGraph(modules: { [string]: any })
	local graph = {}

	for name, mod in modules do
		local deps = mod.Dependencies or {}
		graph[name] = deps
	end

	return graph
end

local function detectCycles(graph) -- ai made
	local visited = {}
	local stack = {}

	local function visit(node, path)
		if stack[node] then
			error(`Circular dependency detected: {table.concat(path, " -> ")} -> {node}`)
		end

		if visited[node] then
			return
		end

		visited[node] = true
		stack[node] = true

		for _, dep in ipairs(graph[node] or {}) do
			visit(dep, { unpack(path), node })
		end

		stack[node] = nil
	end

	for node in graph do
		visit(node, {})
	end
end

local function topoSort(graph) -- ai made
	local visited = {}
	local result = {}

	local function visit(node)
		if visited[node] then
			return
		end
		visited[node] = true

		for _, dep in ipairs(graph[node] or {}) do
			visit(dep)
		end

		table.insert(result, node)
	end

	for node in graph do
		visit(node)
	end

	return result
end

function Controllers:initModules(modules: { [string]: any } & ControllerRegistry) -- ai refactor
	local graph = buildGraph(modules)

	for name, deps in graph do
		for _, dep in deps do
			assert(modules[dep], `Controller '{name}' depends on missing '{dep}'`)
		end
	end

	detectCycles(graph)

	local order = topoSort(graph)

	local promises = {}

	for _, name in ipairs(order) do
		local mod = modules[name]

		self.Register(name, mod)

		if type(mod.Init) == "function" then
			local success, result = pcall(function()
				return mod:Init(registry)
			end)

			if not success then
				warn(`Controller '{name}' crashed during Init: {result}`)
				continue
			end

			if Promise.is(result) then
				local wrapped = Promise.race({
					result,
					Promise.delay(10):andThen(function()
						error(`Controller '{name}' Init timed out`)
					end),
				}):catch(function(err)
					warn(`Controller '{name}' failed async Init: {err}`)
				end)

				table.insert(promises, wrapped)
			end
		end
	end

	return Promise.all(promises)
end

return Controllers
