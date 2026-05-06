--!strict
--<<CLIENT>>--
local Maid = require("@game/ReplicatedStorage/Packages/maid")

export type ItemListener = (tool: Tool, maid: Maid.Maid) -> ()

return function(tool: Tool, _maid: Maid.Maid)
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
