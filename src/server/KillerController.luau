--!strict
--[=[
    Main killer controller stuff
	@class KillerController
    @author: santi-luly1

    CHANGELOG: [
		01/09/26 --> Adapted from original source.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------

local Packages = game:GetService("ReplicatedStorage").Packages

local Promise = require(Packages:WaitForChild("promise"))
local t = require(Packages:WaitForChild("t"))

local KillerController = {
	_init = false,
	_start = false,
}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local Killers = game:GetService("ServerStorage"):WaitForChild("Killers", 5)

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type TypedPromise<T> = Promise.TypedPromise<T>
export type TYPE = "a" | "b"
local TYPE = t.optional(t.string)

--------------------------------------------------------------------
--- ServiceBag (not currently using service bag)
--------------------------------------------------------------------
function KillerController:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
    self._init = true
end

function KillerController:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
    self._start = true
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function KillerController:doSomething(a: TYPE): Promise<nil>
    return Promise.new(function(resolve, reject, onCancel)
        if not TYPE(a) then
			return reject(`[{script.Name}] bad argument #1 (string expected)`)
		end

        if onCancel(function()
            -- cancel the promise
        end) then return end
        
        return resolve()
	end)
end

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

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------


return KillerController