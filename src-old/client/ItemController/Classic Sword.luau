--!strict
--<<CLIENT>>--
local Players = game:GetService("Players")
local Maid = require("@game/ReplicatedStorage/Packages/maid")

local player = Players.LocalPlayer
local Mouse_Icon = "rbxasset://textures/GunCursor.png"
local Reloading_Icon = "rbxasset://textures/GunWaitCursor.png"
local mouse = player:GetMouse()

return function(tool: Tool, maid: Maid.Maid)
	local function updateIcon()
		mouse.Icon = tool.Enabled and Mouse_Icon or Reloading_Icon
	end

	maid:GiveTask(tool.Equipped:Connect(updateIcon))
	maid:GiveTask(tool.Unequipped:Connect(function()
		mouse.Icon = ""
	end))
	maid:GiveTask(tool:GetPropertyChangedSignal("Enabled"):Connect(updateIcon))

	tool.Destroying:Once(function()
		mouse.Icon = ""
	end)
end
