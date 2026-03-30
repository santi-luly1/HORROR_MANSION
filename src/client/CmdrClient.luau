--[=[
	@class CmdrClient
    @author santi-luly1
    @description Cmdr client initializer

    CHANGELOG: [
		01/01/26 --> Added Cmdr for initialization only.
		01/02/25 --> Fixed client sided error.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript)
local CmdrConfig = require(ReplicatedStorage.Shared.CmdrConfig)
local Types = require(script.Parent.Types.CmdrClientTypes)

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local CmdrClient = {
	_init = false,
	_start = false,
} :: Types.CmdrClient

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function CmdrClient:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true
end

function CmdrClient:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	if table.find(CmdrConfig.Permissions.Admin, player.UserId) then
		Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
	end
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------

return CmdrClient
