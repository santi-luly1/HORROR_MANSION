--!strict
--<<SERVER>>--
local Maid = require("@game/ReplicatedStorage/Packages/maid")

export type BehaviorModule = (tool: Tool, player: Player, maid: Maid.Maid) -> ()

return function(tool: Tool, _player: Player, maid: Maid.Maid)
	local handle = tool:FindFirstChild("Handle") :: Part
	local spotLight = handle:FindFirstChild("SpotLight") :: SpotLight
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://115959318"
	sound.Volume = 1
	sound.Parent = handle

	maid:GiveTask(tool.Activated:Connect(function()
		spotLight.Enabled = not spotLight.Enabled
		sound:Play()
	end))
end
