--!strict
--<<SERVER>>--
local Maid = require("@packages/maid")

export type BehaviorModule = (tool: Tool, player: Player, maid: Maid.Maid) -> ()

return function(tool: Tool, _player: Player, _maid: Maid.Maid)
	-- listen
	tool.Activated:Connect(function()
		print("Active")
	end)

	tool.Equipped:Connect(function()
		print("Equip")
	end)

	tool.Unequipped:Connect(function()
		print("Unequip")
	end)
end
