--!strict
--[=[
    Service registry
	@class Services
    @author: santi-luly1

    CHANGELOG: [
		03/01/26 --> Initial version of the module.
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
local registry: { [string]: any } = {}

local pending: { [string]: { (any) -> () } } = {}

function Services.Register<T>(name: string, service: T)
	assert(not registry[name], `Service '{name}' already registered`)
	registry[name] = service

	-- Notify anyone waiting
	local callbacks = pending[name]
	if callbacks then
		for _, cb in ipairs(callbacks) do
			task.spawn(cb, service)
		end
		pending[name] = nil
	end
end

function Services.Get<T>(name: string): T
	local service = registry[name]
	assert(service, `Service '{name}' not found.`)
	return service
end

function Services.WaitFor<T>(name: string, timeout: number?): T
	if registry[name] then
		return registry[name]
	end

	timeout = timeout or 5

	local _, result = Promise.new(function(resolve, reject)
		pending[name] = pending[name] or {}
		table.insert(pending[name], resolve)

		task.delay(timeout, function()
			if not registry[name] then
				reject(`Timeout waiting for service '{name}'`)
			end
		end)
	end):await()

	return result
end

function Services.initModules(modules: { [string]: any }, methodName: string)
	local promises = {}

	for name, mod in modules do
		local method = mod[methodName]
		if type(method) == "function" then
			local success, result = pcall(method, mod)
			if success and Promise.is(result) then
				local timeoutPromise = Promise.delay(10):andThen(function()
					error(`Service '{name}' timed out during {methodName}`)
				end)

				table.insert(
					promises,
					Promise.race({ result, timeoutPromise }):catch(function(err)
						warn(`Service '{name}' failed during {methodName}: {err}`)
					end)
				)
			end
		end
	end

	return Promise.all(promises)
end

return Services
