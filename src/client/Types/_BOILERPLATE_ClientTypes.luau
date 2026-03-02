--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Promise = require(Packages:WaitForChild("promise"))

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>
export type TYPE = "a" | "b"

export type _BOILERPLATE_Client = {
	-- lifecycle
	Init: (self: _BOILERPLATE_Client) -> (),
	Start: (self: _BOILERPLATE_Client) -> (),

	-- private
	_init: boolean,
	_start: boolean,

	-- private methods
	doSomething: (self: _BOILERPLATE_Client, a: TYPE) -> TypedPromise<()>,
}

return (nil :: any) :: _BOILERPLATE_Client
