--!strict
--[=[
    Mainly to recive tools from the server, so we can handle the client side.
	@class ItemController
    @author: santi-luly1

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

local ItemControllerNet = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("ItemController"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local ItemController = {
	_listeners = {},
	_maids = {} :: { [Tool]: Maid.Maid },
}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local default = require(script:WaitForChild("Default"))

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function ItemController:Init()
	for _, module in ipairs(script:GetChildren()) do
		if module.Name == "Default" then
			continue
		end

		self._listeners[module.Name] = require(module) :: default.ItemListener
	end

	ItemControllerNet.ItemGranted.OnClientEvent:Connect(function(tool: Tool)
		local listenerClass: default.ItemListener = self._listeners[tool.Name]

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
