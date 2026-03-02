export type CmdrClient = {
	-- lifecycle
	Init: (self: CmdrClient) -> (),
	Start: (self: CmdrClient) -> (),

	-- private
	_init: boolean,
	_start: boolean,
}

return (nil :: any) :: CmdrClient
