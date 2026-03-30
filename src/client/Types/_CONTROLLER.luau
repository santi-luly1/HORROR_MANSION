--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------

export type CONTROLLER<T> = {
	-- lifecycle
	Init: (self: T, registry: { [string]: any }) -> (),
	Start: (self: T) -> (),

	-- public API

	-- events

	-- private
	_init: boolean,
	_start: boolean,
	Dependencies: { string? },

	-- private methods
}

--return (nil :: any) :: CONTROLLER<...> -- ugly, but used by Controllers.luau
return nil
