--The only objetive for this is to reexport the types for LLS

local Signal = require(script.Parent._Index["sleitnick_signal@2.0.3"]["signal"])

--------------------------------------------------------------------
--- Types reexport (LLS wasn't happy)
--------------------------------------------------------------------
--export type Signal<T...> = Signal.Signal<T...>

return Signal