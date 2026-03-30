--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Promise = require(Packages:WaitForChild("promise"))
local _CONTROLLER = require(script.Parent._CONTROLLER)

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
