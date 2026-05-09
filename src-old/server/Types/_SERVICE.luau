--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type SERVICE<T> = {
	-- lifecycle
	Init: (self: T, registry: { [string]: any }) -> (), -- would prefer that registry was Service.ServiceRegistry, but it makes cyclic deps.
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
