--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Promise = require("@game/ReplicatedStorage/Packages/promise")
local _CONTROLLER = require("@game/StarterPlayer/StarterPlayerScripts/Client/Types/_CONTROLLER")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TypedPromise<T...> = Promise.TypedPromise<T...>

export type _BOILERPLATE_Controller = _CONTROLLER.CONTROLLER<_BOILERPLATE_Controller> & {
	-- private methods
	doSomething: (self: _BOILERPLATE_Controller, a: TYPE) -> TypedPromise<()>,
}

export type TYPE = "a" | "b"

return (nil :: any) :: _BOILERPLATE_Controller
