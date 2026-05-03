--!strict
--[=[
	@class CmdrServer
    @author santi-luly1
	@description Cmdr server initializer

    CHANGELOG: [
		01/01/26 --> Added Cmdr for initialization only.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
-- Roblox services

-- Packages
local Cmdr = require("@serverPackages/cmdr")

-- Types
local Types = require("@serverTypes/CmdrServerTypes")

-- Networking

-- Local utilities

-- Services

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local CmdrServer = {
	_init = false,
	_start = false,
} :: Types.CmdrServer

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------

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
