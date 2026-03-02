--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Promise = require(Packages:WaitForChild("promise"))

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

export type _BOILERPLATE_Server = {
	-- lifecycle
	Init: (self: _BOILERPLATE_Server) -> (),
	Start: (self: _BOILERPLATE_Server) -> (),

	-- public API

	-- events

	-- private
	_init: boolean,
	_start: boolean,

	-- private methods
	doSomething: (self: _BOILERPLATE_Server, a: TYPE) -> TypedPromise<()>,
}

export type TYPE = "a" | "b"

return (nil :: any) :: _BOILERPLATE_Server
