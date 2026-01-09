--The only objetive for this is to reexport the types for LLS

local Promise = require(script.Parent._Index["lukadev-0_typed-promise@4.0.2"]["typed-promise"])

--------------------------------------------------------------------
--- Types reexport (LLS wasn't happy)
--------------------------------------------------------------------
export type Status = Promise.Status
export type Promise = Promise.Promise
export type TypedPromise<T...> = Promise.TypedPromise<T...>

return Promise