--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Promise = require("@packages/promise")
local _SERVICE = require("@serverTypes/_SERVICE")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

export type _BOILERPLATE_Server = _SERVICE.SERVICE<_BOILERPLATE_Server> & {
	-- private methods
	doSomething: (self: _BOILERPLATE_Server, a: TYPE) -> TypedPromise<()>,
}

export type TYPE = "a" | "b"

return (nil :: any) :: _BOILERPLATE_Server
