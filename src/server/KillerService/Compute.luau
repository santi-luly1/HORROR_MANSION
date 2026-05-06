--!strict
local Maid = require("@game/ReplicatedStorage/Packages/maid")
local simplepath = require("@game/ReplicatedStorage/Packages/simplepath")

-- each killer gets its own entry via the model as key
local pathRegistry = setmetatable({} :: { [Model]: { target: Model?, path: any } }, { __mode = "k" })

return function(
	model: Model,
	maid: Maid.Maid
): boolean -- FIXME: Sometimes you need to get close to the killer to notice you.
	local hrp = model:FindFirstChild("HumanoidRootPart") :: Part?
	if not hrp then
		warn(`{model:GetFullName()} lacks HumanoidRootPart`)
		return false
	end

	local ok, target = pcall(function() -- This can fail (ej. we don't have an HRP, so it's nil, making this fail)
		return simplepath.GetNearestCharacter(hrp.Position)
	end)

	if not ok or not target then
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

	local k, result = pcall(function()
		return data.path:Run(target:GetPivot().Position) :: boolean
	end)

	return k and result or false
end
