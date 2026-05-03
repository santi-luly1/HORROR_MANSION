--!strict
--<<CLIENT>>--
local Players = game:GetService("Players")
local Maid = require("@packages/maid")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local MOUSE_ICON = "rbxasset://textures/GunCursor.png"
local RELOADING_ICON = "rbxasset://textures/GunWaitCursor.png"

return function(tool: Tool, maid: Maid.Maid)
	--Rescripted by Luckymaxer
	--[MODIFIED]

	-- those `Infinite yield` errors were annoying me
	local ServerControl = tool:WaitForChild("ServerControl", 120) :: RemoteFunction
	local ClientControl = tool:WaitForChild("ClientControl", 120) :: RemoteFunction

	local Character
	local Humanoid

	local function InvokeServer(Mode: string, Value: any, arg: any)
		pcall(function()
			ServerControl:InvokeServer(Mode, Value, arg)
		end)
	end

	ClientControl.OnClientInvoke = function(Mode: string, Value: any)
		if Mode == "PlaySound" and Value then
			Value:Play()
		end
	end

	maid:GiveTask(tool.Equipped:Connect(function()
		Character = tool.Parent :: Model

		Humanoid = Character:FindFirstChildOfClass("Humanoid")
		if not player or not Humanoid or Humanoid.Health == 0 then
			return
		end
		maid:GiveTask(mouse.Button1Down:Connect(function()
			InvokeServer("Click", true, mouse.Hit.Position)
		end))
	end))

	maid:GiveTask(tool.Unequipped:Connect(function()
		Character = nil :: any
		Humanoid = nil
		mouse.Icon = ""
	end))

	local function updateIcon()
		mouse.Icon = tool.Enabled and MOUSE_ICON or RELOADING_ICON
	end

	maid:GiveTask(tool.Equipped:Connect(function()
		ServerControl = tool:WaitForChild("ServerControl") :: RemoteFunction
		ClientControl = tool:WaitForChild("ClientControl") :: RemoteFunction

		updateIcon()
	end))
	maid:GiveTask(tool:GetPropertyChangedSignal("Enabled"):Connect(updateIcon))
end
