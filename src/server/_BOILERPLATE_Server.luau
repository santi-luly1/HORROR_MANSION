--!strict
--[=[
	@class _BOILERPLATE_Server
    @author author
    @description Boilerplate for server stuff

    CHANGELOG: [
		MM/DD/YY --> change
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
-- Roblox services

-- Packages
local Promise = require("@game/ReplicatedStorage/Packages/promise")
local t = require("@game/ReplicatedStorage/Packages/t")

-- Types
local Types = require("@game/ServerScriptService/Server/Types/_BOILERPLATE_ServerTypes")

-- Networking

-- Local utilities

-- Services

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local _BOILERPLATE_Server = {
	_init = false,
	_start = false,
} :: Types._BOILERPLATE_Server
_BOILERPLATE_Server.Dependencies = {}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local _

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
local TYPE = t.optional(t.string)

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function _BOILERPLATE_Server:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true
end

function _BOILERPLATE_Server:Start()
	assert(self._init, `[{script.Name}] - Module not initialized.`)
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------
function _BOILERPLATE_Server:doSomething(a: Types.TYPE): Types.TypedPromise<()>
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

return _BOILERPLATE_Server
