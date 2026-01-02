--!strict
--[=[
    cmdr client initializer
	@class CmdrClient
    @author: santi-luly1

    CHANGELOG: [
		01/01/26 --> Added cmdr for initialization only.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Cmdr = require(Packages:WaitForChild("cmdr"))

local CmdrClient = {
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
function CmdrClient:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
    self._init = true
end

function CmdrClient:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
    self._start = true

    Cmdr:SetActivationKeys({ Enum.KeyCode.Q })
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------


return CmdrClient