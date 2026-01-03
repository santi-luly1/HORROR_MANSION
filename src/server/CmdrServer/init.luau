--!strict
--[=[
    Cmdr server initializer
	@class cmdrServer
    @author: santi-luly1

    CHANGELOG: [
		01/01/26 --> Added Cmdr for initialization only.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Cmdr = require(Packages:WaitForChild("cmdr"))

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

--------------------------------------------------------------------
--- ServiceBag (not currently using service bag)
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
--- Handlers
--------------------------------------------------------------------

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------


return CmdrServer