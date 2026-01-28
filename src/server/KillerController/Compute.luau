--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local simplepath = require(ReplicatedStorage.Packages.simplepath)

local lastTarget: Model? = nil
local lastPath = nil

return function(model: Model, maid: any): boolean -- typecheck for maid? not rn..
	local hrp = model:FindFirstChild("HumanoidRootPart") :: Part?
	if not hrp then
		warn(`{model:GetFullName()} lacks HumanoidRootPart`)
		return false
	end

	local target = simplepath.GetNearestCharacter(hrp.Position)
	if not target then
		return false
	end

	local human = target:FindFirstChildOfClass("Humanoid")
	if not human or human.Health <= 0 then
		return false
	end

	if target:FindFirstChildOfClass("ForceField") then
		return false
	end -- FIXME: for some reason, just 1 killer works at the same time. (kind of)

	if target ~= lastTarget or not lastPath then
		lastPath = simplepath.new(model, {
			AgentHeight = 5,
			AgentRadius = 2,
			AgentCanJump = true,
			Costs = { Roof = math.huge }, --really?
		})
		lastTarget = target

		maid:GiveTask(function()
			lastTarget = nil
		end)
		maid:GiveTask(lastPath)
	end

	return lastPath:Run(target:GetPivot().Position) :: boolean
end
