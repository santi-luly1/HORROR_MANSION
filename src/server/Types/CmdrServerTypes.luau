--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type CmdrServer = {
	-- lifecycle
	Init: (self: CmdrServer) -> (),
	Start: (self: CmdrServer) -> (),

	-- public API

	-- events

	-- private
	_init: boolean,
	_start: boolean,

	-- private methods
}

return nil
