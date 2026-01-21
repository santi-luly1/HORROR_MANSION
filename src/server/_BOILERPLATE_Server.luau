--!strict
--[=[
    Boilerplate for server stuff
	@class _BOILERPLATE_Server
    @author: santi-luly1

    CHANGELOG: [
		MM/DD/YY --> change
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Promise = require(Packages:WaitForChild("promise"))
local t = require(Packages:WaitForChild("t"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local _BOILERPLATE_Server = {
	_init = false,
	_start = false,
} :: _BOILERPLATE_Server

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local _

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type TypedPromise<T...> = Promise.TypedPromise<T...>

type _BOILERPLATE_Server = {
	-- lifecycle
	Init: (self: _BOILERPLATE_Server) -> (),
	Start: (self: _BOILERPLATE_Server) -> (),

	-- public API

	-- events

	-- private
	_init: boolean,
	_start: boolean,

	-- private methods
	doSomething: (self: _BOILERPLATE_Server, a: TYPE) -> TypedPromise<>,
}

export type TYPE = "a" | "b"
local TYPE = t.optional(t.string)

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function _BOILERPLATE_Server:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true
end

function _BOILERPLATE_Server:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function _BOILERPLATE_Server:doSomething(a: TYPE): TypedPromise<>
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
