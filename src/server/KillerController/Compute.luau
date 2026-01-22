--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local simplepath = require(ReplicatedStorage.Packages.simplepath)

return function(model: Model, maid: any): boolean
	local torso = model:FindFirstChild("HumanoidRootPart") :: Part
	if not torso then
		warn(`{model:GetFullName()} has no HRP`)
		return false
	end

	local target = simplepath.GetNearestCharacter(torso.Position)
	if not target or target.Humanoid.Health <= 0 or target:FindFirstChildOfClass("ForceField") then -- probably this will be a semi-bug, since if the same person stays close to it with a FF, it'll always reject.
		warn(`{model:GetFullName()} has not found any character`)
		return false
	end

	local path =
		simplepath.new(model, { -- maybe this is a bad idea? maid cleans it every round, but is it still good tho?
			AgentHeight = 5,
			AgentRadius = 2,
			AgentCanJump = true,
			Costs = {
				Roof = math.huge,
			},
		})

	maid:GiveTask(function()
		path:Destroy()
	end)

	return path:Run(target:GetPivot().Position) :: boolean
end
