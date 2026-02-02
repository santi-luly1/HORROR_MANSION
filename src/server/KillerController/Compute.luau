--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local simplepath = require(ReplicatedStorage.Packages.simplepath)

-- each killer gets its own entry via the model as key
local pathRegistry = setmetatable({} :: { [Model]: { target: Model?, path: any } }, { __mode = "k" })

return function(
	model: Model,
	maid: any
): boolean -- typecheck for maid? not rn.. -> FIXME: Sometimes you need to get close to the killer to notice you.
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
	end

	local data = pathRegistry[model]
	if not data then
		data = { target = nil, path = nil }
		pathRegistry[model] = data

		maid:GiveTask(function()
			pathRegistry[model].path:Destroy()
			pathRegistry[model] = nil
		end)
	end

	if target ~= data.target or not data.path then
		data.target = target
		data.path = simplepath.new(model, {
			AgentHeight = 5,
			AgentRadius = 2,
			AgentCanJump = true,
			Costs = { Roof = math.huge }, --really?
		})
	end

	return data.path:Run(target:GetPivot().Position) :: boolean
end
