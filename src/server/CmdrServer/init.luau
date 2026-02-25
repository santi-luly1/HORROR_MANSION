--!strict
--[=[
    Cmdr server initializer
	@class CmdrServer
    @author: santi-luly1

    CHANGELOG: [
		01/01/26 --> Added Cmdr for initialization only.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ServerPackages = script.Parent.Packages
local Cmdr = require(ServerPackages:WaitForChild("cmdr"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local CmdrServer = {
	_init = false,
	_start = false,
}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type CmdrServer = {
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

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function CmdrServer:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true
end

function CmdrServer:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	Cmdr:RegisterCommandsIn(script.Commands)
	Cmdr:RegisterHooksIn(script.Hooks)
	Cmdr:RegisterTypesIn(script.Types)
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------

return CmdrServer
