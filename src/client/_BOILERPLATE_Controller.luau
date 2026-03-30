--!strict
--[=[
	@class _BOILERPLATE_Controller
    @author author
    @description Boilerplate for client stuff

    CHANGELOG: [
		MM/DD/YY --> change
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Promise = require(Packages:WaitForChild("promise"))
local Types = require(script.Parent.Types._BOILERPLATE_ControllerTypes)
local t = require(Packages:WaitForChild("t"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local _BOILERPLATE_Controller = {
	_init = false,
	_start = false,
} :: Types._BOILERPLATE_Controller

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local _

local TYPE = t.optional(t.string)

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function _BOILERPLATE_Controller:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true
end

function _BOILERPLATE_Controller:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------
function _BOILERPLATE_Controller:doSomething(a: Types.TYPE): Types.TypedPromise<()>
	return Promise.new(function(resolve, reject, onCancel)
		if not TYPE(a) then
			return reject(`[{script.Name}] bad argument #1 (string expected)`)
		end

		if
			onCancel(function()
				-- cancel the promise
			end)
		then
			return
		end

		return resolve()
	end)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------

return _BOILERPLATE_Controller
