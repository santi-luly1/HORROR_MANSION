--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Maid = require("@game/ReplicatedStorage/Packages/maid")
local _CONTROLLER = require("@game/StarterPlayer/StarterPlayerScripts/Client/Types/_CONTROLLER")

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
