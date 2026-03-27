export type PlayerDeathHandler = {
	-- lifecycle
	Init: (self: PlayerDeathHandler) -> (),
	Start: (self: PlayerDeathHandler) -> (),

	-- private
	_init: boolean,
	_start: boolean,
}

return nil
