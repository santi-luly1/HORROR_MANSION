--!strict
--[=[
    Controllers registry
	@class Controllers
    @author: santi-luly1

    CHANGELOG: [
		03/01/26 --> Initial version of the module.
	]
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.promise)
local Types = script.Parent.Types

export type ControllerRegistry = {
	CmdrClient: typeof(require(Types.CmdrClientTypes)),
	ItemController: typeof(require(Types.ItemControllerTypes)),
	UI: typeof(require(Types.UITypes)),
	_BOILERPLATE_Client: typeof(require(Types._BOILERPLATE_ClientTypes)),
}

local Controllers = {}
local registry: { [string]: any } = {}

local pending: { [string]: { (any) -> () } } = {}

function Controllers.Register<T>(name: string, controller: T)
	assert(not registry[name], `Controller '{name}' already registered`)
	registry[name] = controller

	-- Notify anyone waiting
	local callbacks = pending[name]
	if callbacks then
		for _, cb in ipairs(callbacks) do
			task.spawn(cb, controller)
		end
		pending[name] = nil
	end
end

function Controllers.Get<T>(name: string): T
	local controller = registry[name]
	assert(controller, `Controller '{name}' not found.`)
	return controller
end

function Controllers.WaitFor<T>(name: string, timeout: number?): T
	if registry[name] then
		return registry[name]
	end

	timeout = timeout or 5

	local _, result = Promise.new(function(resolve, reject)
		pending[name] = pending[name] or {}
		table.insert(pending[name], resolve)

		task.delay(timeout, function()
			if not registry[name] then
				reject(`Timeout waiting for controller '{name}'`)
			end
		end)
	end):await()

	return result
end

function Controllers.initModules(modules: { [string]: any }, methodName: string)
	local promises = {}

	for name, mod in modules do
		local method = mod[methodName]
		if type(method) == "function" then
			local success, result = pcall(method, mod)
			if success and Promise.is(result) then
				local timeoutPromise = Promise.delay(10):andThen(function()
					error(`Controller '{name}' timed out during {methodName}`)
				end)

				table.insert(
					promises,
					Promise.race({ result, timeoutPromise }):catch(function(err)
						warn(`Controller '{name}' failed during {methodName}: {err}`)
					end)
				)
			end
		end
	end

	return Promise.all(promises)
end

return Controllers
