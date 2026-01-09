local KillersController = {}

function KillersController:SpawnKillerByName(name)
	local killersFolder = self._serverStorage:FindFirstChild("Killers")
	if not killersFolder then
		return nil, "No Killers folder"
	end

	local candidate = killersFolder:FindFirstChild(name)
	if not candidate then
		return nil, "Killer not found"
	end

	if not self._workspace:FindFirstChild("Killer") then
		local killerFolder = Instance.new("Folder")
		killerFolder.Name = "Killer"
		killerFolder.Parent = self._workspace
	end
	clearWorkspaceKillers(self._workspace)

	local clone = candidate:Clone()
	clone.Parent = self._workspace.Killer

	self._killerAI.Start(clone)

	local initMod = clone:FindFirstChild("Init") or clone:FindFirstChild("Controller")
	if initMod and initMod:IsA("ModuleScript") then
		local ok, m = pcall(require, initMod)
		if ok and type(m.Init) == "function" then
			m.Init(clone)
		elseif ok and type(m.Start) == "function" then
			m.Start(clone)
		end
	end

	return clone
end

function KillersController:SpawnRandomKiller()
	local killersFolder = self._serverStorage:FindFirstChild("Killers")
	if not killersFolder then
		return nil, "No Killers folder"
	end

	local list = killersFolder:GetChildren()
	if #list == 0 then
		return nil, "No killers available"
	end

	local selected = list[math.random(1, #list)]
	return self:SpawnKillerByName(selected.Name)
end

function KillersController:Clear()
	clearWorkspaceKillers(self._workspace)
end

function KillersController:GetActive()
	if self._workspace:FindFirstChild("Killer") then
		for _, v in ipairs(self._workspace.Killer:GetChildren()) do
			if v:IsA("Model") then
				return v
			end
		end
	end
	return nil
end

return KillersController
