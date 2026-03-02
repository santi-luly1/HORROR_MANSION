--!strict
--[=[
    Boilerplate for client stuff
	@class _BOILERPLATE_Client
    @author: santi-luly1

    CHANGELOG: [
		MM/DD/YY --> change
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Controllers = require(script.Parent.Controllers)
local Promise = require(Packages:WaitForChild("promise"))
local Types = require(script.Parent.Types._BOILERPLATE_ClientTypes)
local t = require(Packages:WaitForChild("t"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local _BOILERPLATE_Client = {
	_init = false,
	_start = false,
} :: Types._BOILERPLATE_Client

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local _

local TYPE = t.optional(t.string)

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function _BOILERPLATE_Client:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true
end

function _BOILERPLATE_Client:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	Controllers.Register(script.Name, self)
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------
function _BOILERPLATE_Client:doSomething(a: Types.TYPE): Types.TypedPromise<()>
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

return _BOILERPLATE_Client
