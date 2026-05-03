--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Maid = require("@packages/maid")
local _CONTROLLER = require("@clientTypes/_CONTROLLER")

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type ItemListener = (tool: Tool, maid: Maid.Maid) -> ()

export type ItemController = _CONTROLLER.CONTROLLER<ItemController> & {
	-- private
	_listeners: { [string]: ItemListener },
	_maids: { [Tool]: Maid.Maid },

	-- private methods
	_cleanup: (self: ItemController, tool: Tool) -> (),
}

return (nil :: any) :: ItemController
