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
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript)
local CmdrConfig = require(ReplicatedStorage.Shared.CmdrConfig)

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local CmdrClient = {
	_init = false,
	_start = false,
} :: CmdrClient

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type CmdrClient = {
	-- lifecycle
	Init: (self: CmdrClient) -> (),
	Start: (self: CmdrClient) -> (),

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
--- Handlers
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------

return CmdrClient
