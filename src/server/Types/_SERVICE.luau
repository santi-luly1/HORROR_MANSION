--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------

export type SERVICE<T> = {
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

--return (nil :: any) :: SERVICE<...> -- ugly, but used by Services.luau
return nil
