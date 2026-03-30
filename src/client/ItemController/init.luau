--!strict
--[=[
	@class ItemController
    @author santi-luly1
    @description Mainly to recive tools from the server, so we can handle the client side

    CHANGELOG: [
		02/25/26 --> Initial version of the module.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Maid = require(Packages:WaitForChild("maid"))
local Types = require(script.Parent.Types.ItemControllerTypes)

local ItemControllerNet = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("ItemControllerNetwork"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local ItemController = {
	_init = false,
	_start = false,
	_listeners = {},
	_maids = {},
} :: Types.ItemController

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
require(script:WaitForChild("Default"))

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function ItemController:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	for _, module in ipairs(script:GetChildren()) do
		if module.Name == "Default" then
			continue
		end

		self._listeners[module.Name] = require(module) :: Types.ItemListener
	end

	ItemControllerNet.ItemGranted.OnClientEvent:Connect(function(tool: Tool)
		local listenerClass: Types.ItemListener = self._listeners[tool.Name]

		if not listenerClass then -- we don't really want a "default" for the client.
			return
		end

		local maid = Maid.new()
		listenerClass(tool, maid)

		self._maids[tool] = maid

		tool.Destroying:Once(function()
			self:_cleanup(tool)
		end)
	end)
end

function ItemController:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------
function ItemController:_cleanup(tool: Tool)
	local maid = self._maids[tool]
	if maid then
		maid:Destroy()
		self._maids[tool] = nil
	end
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------

return ItemController
