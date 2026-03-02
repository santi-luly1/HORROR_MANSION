--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")

local Maid = require(Packages:WaitForChild("maid"))

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type ItemListener = (tool: Tool, maid: Maid.Maid) -> ()

export type ItemController = {
	-- lifecycle
	Init: (self: ItemController) -> (),
	Start: (self: ItemController) -> (),

	-- private
	_init: boolean,
	_start: boolean,
	_listeners: { [string]: ItemListener },
	_maids: { [Tool]: Maid.Maid },

	-- private methods
	_cleanup: (self: ItemController, tool: Tool) -> (),
}

return (nil :: any) :: ItemController
