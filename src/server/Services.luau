--!strict
--[=[
	@class Services
    @author santi-luly1
    @description Service registry

    CHANGELOG: [
		03/01/26 --> Initial version of the module.
		03/30/26 --> Dependency graph (ai refactor).
	]
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.promise)
local Types = script.Parent.Types

export type ServiceRegistry = {
	VotingController: typeof(require(Types.VotingControllerTypes)),
	RoundController: typeof(require(Types.RoundControllerTypes)),
	KillerController: typeof(require(Types.KillerControllerTypes)),
	ItemController: typeof(require(Types.ItemControllerTypes)),
	PlayerDataHandler: typeof(require(Types.PlayerDataHandlerTypes)),
	PlayerDeathHandler: typeof(require(Types.PlayerDeathHandlerTypes)),
}

local Services = {}
local registry = {} :: ServiceRegistry

function Services.Register<T>(name: string, service: T)
	assert(not registry[name], `Service '{name}' already registered`)
	registry[name] = service
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

function Services:initModules(modules: { [string]: any } & ServiceRegistry) -- ai refactor
	local graph = buildGraph(modules)

	for name, deps in graph do
		for _, dep in deps do
			assert(modules[dep], `Service '{name}' depends on missing '{dep}'`)
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
				warn(`Service '{name}' crashed during Init: {result}`)
				continue
			end

			if Promise.is(result) then
				local wrapped = Promise.race({
					result,
					Promise.delay(10):andThen(function()
						error(`Service '{name}' Init timed out`)
					end),
				}):catch(function(err)
					warn(`Service '{name}' failed async Init: {err}`)
				end)

				table.insert(promises, wrapped)
			end
		end
	end

	return Promise.all(promises)
end

return Services
