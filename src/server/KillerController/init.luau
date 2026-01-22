--!strict
--[=[
    Main killer controller stuff
	@class KillerController
    @author: santi-luly1

    CHANGELOG: [
		01/10/26 --> Adapted from original source.
		01/11/26 --> Added module-wide typechecking and random spawn selector with its APIs
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Compute = require(script:WaitForChild("Compute"))
local Maid = require(Packages:WaitForChild("maid"))
local Promise = require(Packages:WaitForChild("promise"))
--local SpecialKillerBehaviour = require(script:WaitForChild("SpecialKillerBehaviour"))
local t = require(Packages:WaitForChild("t"))

local KillerControllerNet = require(Networking:WaitForChild("KillerController"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local KillerController = {
	_init = false,
	_start = false,
	_currentKiller = nil,
	_maid = Maid.new(),
} :: KillerController

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local Killers = game:GetService("ServerStorage"):WaitForChild("Killers", 5)
local killersList = Killers:GetChildren() :: { Model }
local enum = { "any" }

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type TypedPromise<T...> = Promise.TypedPromise<T...>
type KillerController = {
	-- lifecycle
	Init: (self: KillerController) -> (),
	Start: (self: KillerController) -> (),

	-- public API
	SpawnKiller: (self: KillerController, name: string?, spawnIndex: number?) -> TypedPromise<Model, number>,
	GetCurrentKiller: (self: KillerController) -> Model?,
	ClearCurrentKiller: (self: KillerController) -> (),
	GetKillersName: (self: KillerController) -> { string },

	-- private
	_currentKiller: Model?,
	_maid: Maid.Maid,
	_init: boolean,
	_start: boolean,
	_spawnKillerByName: (self: KillerController, name: string, spawnIndex: number?) -> TypedPromise<Model, number>,
	_spawnRandomKiller: (self: KillerController, spawnIndex: number?) -> TypedPromise<Model, number>,
}

local nameCheck = t.string

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function KillerController:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	-- handle client requests
	KillerControllerNet.GetKillersName.OnServerInvoke = function()
		return self:GetKillersName()
	end
end

function KillerController:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	-- self:_spawnRandomKiller(nil)
	-- 	:andThen(function(_, killer: Model)
	-- 		print(killer, killer:GetFullName())
	-- 	end)
	-- 	:catch(warn)

	for _, killer in ipairs(Killers:GetChildren()) do
		table.insert(enum, killer.Name)
	end
end

--------------------------------------------------------------------
--- Helpers
--------------------------------------------------------------------
--- gets a random spawn, or the indexed spawn's CFrame with 10 studs headroom along with its index
local function getRandomSpawnCFrame(index: number?): (number, CFrame)
	local mapSpawns = workspace.Map.spawns:GetChildren() :: { SpawnLocation }
	index = math.clamp(index or math.random(1, #mapSpawns), 1, #mapSpawns)
	return index :: number, mapSpawns[index :: number].CFrame * CFrame.new(0, 10, 0)
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function KillerController:_spawnKillerByName(name: string, spawnIndex: number?): TypedPromise<Model, number>
	return Promise.new(function(resolve, reject, onCancel)
		if not nameCheck(name) then
			return reject(`[{script.Name}] bad argument #1 (string expected)`)
		end
		self:ClearCurrentKiller() -- just making sure, but maybe on the future there could be multiple killers at once... Interesting..

		local maid = self._maid

		if onCancel(function()
			maid:Destroy()
		end) then
			return
		end

		local candidate = Killers:FindFirstChild(name) :: Model
		if not candidate then
			return reject("Killer not found")
		end

		local clone = candidate:Clone()
		local hrp = clone:FindFirstChild("HumanoidRootPart") :: Part
		local index, killerCFrame = getRandomSpawnCFrame(spawnIndex)
		clone.Parent = workspace
		hrp.CFrame = killerCFrame

		local hitbox = clone:FindFirstChild("hitbox") :: Part
		maid:GiveTask(hitbox.Touched:Connect(function(hit)
			local character = hit.Parent
			if character and character ~= clone then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 and not character:FindFirstChildOfClass("ForceField") then
					humanoid.Health = 0 -- TODO: Maybe smth else instead of just insta kill?
				end
			end
		end))
		maid:GiveTask(clone)
		self._currentKiller = clone

		maid:GiveTask(task.spawn(function()
			while true do
				local ok = Compute(clone, maid) -- single path
				if not ok then
					task.wait(1)
				else
					--task.wait(0.5) -- repath cadence
				end
			end
		end))

		-- TODO: Make the module "SpecialKillerBehaviour" work in here.
		return resolve(clone, index)
	end)
end
function KillerController:_spawnRandomKiller(spawnIndex: number?): TypedPromise<Model, number>
	local selected = killersList[math.random(1, #killersList)]
	return self:_spawnKillerByName(selected.Name, spawnIndex)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function KillerController:SpawnKiller(name: string?, spawnIndex: number?): TypedPromise<Model, number>
	return name and self:_spawnKillerByName(name, spawnIndex) or self:_spawnRandomKiller(spawnIndex)
end

function KillerController:GetCurrentKiller(): Model?
	return self._currentKiller
end

function KillerController:GetKillersName(): { string }
	return enum
end

function KillerController:ClearCurrentKiller()
	self._maid:Destroy()
	self._currentKiller = nil
end

return KillerController
