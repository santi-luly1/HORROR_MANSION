--[=[
    Cmdr client initializer
	@class CmdrClient
    @author: santi-luly1

    CHANGELOG: [
		01/01/26 --> Added Cmdr for initialization only.
		01/02/25 --> Fixed client sided error.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript)

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

    Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------


return CmdrClient