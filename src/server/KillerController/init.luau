--!strict
--[=[
    Main API for killer(s) management
	@class KillerController
    @author: santi-luly1

    CHANGELOG: [
		01/10/26 --> Adapted from original source.
		01/11/26 --> Added module-wide typechecking and random spawn selector with its APIs.
		01/28/26 --> Added multiple killers support and signals.
		01/30/26 --> Added GetRandomIndex API, and added killer sounds.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Maid = require(Packages:WaitForChild("maid"))
local Promise = require(Packages:WaitForChild("promise"))
--local SpecialKillerBehaviour = require(script:WaitForChild("SpecialKillerBehaviour"))
local Signal = require(Packages:WaitForChild("signal"))
local t = require(Packages:WaitForChild("t"))

local KillerControllerNet = require(Networking:WaitForChild("KillerController"))

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local KillerController = {
	_init = false,
	_start = false,
	_killers = {},
	_maid = nil,
} :: KillerController

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local KillersFolder = ServerStorage:WaitForChild("Killers", 5)
local KillerTemplates = KillersFolder:GetChildren() :: { Model }

local NAMES = table.create(#KillerTemplates + 2, "*")
do
	NAMES[2] = "**"
	for i, m in KillerTemplates do
		NAMES[i + 2] = m.Name
	end
end
local SoundsIndex = require(script.Sounds)

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type TypedPromise<T...> = Promise.TypedPromise<T...>
type KillerController = {
	-- lifecycle
	Init: (self: KillerController) -> (),
	Start: (self: KillerController) -> (),

	-- public API
	SpawnKillers: (self: KillerController, names: { string }, spawnIndex: number) -> TypedPromise<{ Model }>,
	SpawnAll: (self: KillerController, spawnIndex: number) -> TypedPromise<{ Model }>,
	SpawnKiller: (self: KillerController, name: string, spawnIndex: number) -> TypedPromise<Model, number>,
	GetCurrentKillers: (self: KillerController) -> { Model },
	Clear: (self: KillerController) -> (),
	IsValidName: (self: KillerController, name: string) -> boolean,
	GetKillersName: (self: KillerController) -> { string },
	GetRandomIndex: (self: KillerController) -> number,
	KillerSpawned: Signal.Signal<Model, number>,
	KillerCleared: Signal.Signal<string>,

	-- private
	_maid: Maid.Maid,
	_init: boolean,
	_start: boolean,
	_killers: { Model },
	_spawn: (self: KillerController, name: string, spawnIndex: number) -> TypedPromise<Model, number>,
}

local spawnCheck = t.tuple(t.string, t.number)

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function KillerController:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	self._maid = Maid.new()
	self.KillerSpawned = Signal.new()
	self.KillerCleared = Signal.new()
	-- handle client requests
	KillerControllerNet.GetKillersName.OnServerInvoke = function()
		return self:GetKillersName()
	end
end

function KillerController:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true
end

--------------------------------------------------------------------
--- Helpers
--------------------------------------------------------------------
local function getSpawnCFrame(index: number): (number, CFrame)
	local spawns = workspace.Map.spawns:GetChildren() :: { SpawnLocation }
	return index, spawns[index].CFrame * CFrame.new(0, 10, 0)
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function KillerController:_spawn(name: string, spawnIndex: number): TypedPromise<Model, number>
	return Promise.new(function(resolve, reject, onCancel)
		if not spawnCheck(name, spawnIndex) then
			return reject(`[{script.Name}] bad argument(s)`)
		end

		if not self:IsValidName(name) then
			return reject(`Name '{name}' is invalid.`)
		end

		for _, existing in ipairs(self._killers) do
			if existing.Name == name and existing.Parent then
				return reject(`Killer '{name}' already spawned.`) --maybe shoudl I allow this?
			end
		end

		if spawnIndex < 1 then
			spawnIndex = self:GetRandomIndex()
		end

		local maid = Maid.new()

		if onCancel(function()
			maid:Destroy()
		end) then
			return
		end

		local template = KillersFolder:FindFirstChild(name) :: Model?
		if not template then
			return reject("Killer not found")
		end

		local clone = template:Clone()
		local hrp = clone:FindFirstChild("HumanoidRootPart") :: Part

		local index, cf = getSpawnCFrame(spawnIndex)
		clone.Parent = workspace
		hrp.CFrame = cf
		clone:SetAttribute("killer", true)

		table.insert(self._killers, clone)
		maid:GiveTask(clone)
		maid:LinkToInstance(clone) -- would this be an issue with the line above?

		local hitbox = clone:FindFirstChild("hitbox") :: Part
		maid:GiveTask(hitbox.Touched:Connect(function(hit)
			local char = hit.Parent :: Model
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if
				hum
				and hum.Health > 0
				and not char:FindFirstChildOfClass("ForceField")
				and not char:GetAttribute("killer")
			then
				local sounds = SoundsIndex[clone.Name].Kill
				if #sounds > 0 then
					local track = Instance.new("Sound")
					track.SoundId = `rbxassetid://{sounds[math.random(1, #sounds)]}`
					track.Parent = clone.PrimaryPart
					track.Volume = 2 -- maybe a bit too loud.
					track.Ended:Once(function()
						track:Destroy() -- would this even be needed?
					end)
					track:Play()
				end
				hum.Health = 0 -- TODO: Maybe smth else instead of just insta kill?
			end
		end))

		local humanoid = clone:FindFirstChild("Humanoid") :: Humanoid
		humanoid.Died:Once(function()
			maid:Destroy()
		end)

		maid:GiveTask(task.spawn(function()
			local Compute = require(script:WaitForChild("Compute"))

			while clone.Parent do
				local ok = Compute(clone, maid)
				if ok then
					RunService.Heartbeat:Wait() -- sooo smooth
				else
					task.wait(0.5)
				end
			end
		end))

		maid:GiveTask(function()
			for i, k in ipairs(self._killers) do
				if k == clone then
					table.remove(self._killers, i)
					break
				end
			end
			self.KillerCleared:Fire(clone.Name)
		end)

		-- TODO: Make the module "SpecialKillerBehaviour" work in here.
		self._maid:GiveTask(maid)
		self.KillerSpawned:Fire(clone, index)
		return resolve(clone, index)
	end)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function KillerController:SpawnKillers(names: { string }, spawnIndex: number): TypedPromise<{ Model }>
	return Promise.new(function(resolve, reject)
		local promises = {}

		for _, name in ipairs(names) do
			if self:IsValidName(name) then
				table.insert(promises, self:SpawnKiller(name, spawnIndex))
			end
		end

		if #promises == 0 then
			return reject("No valid killers to spawn")
		end

		Promise.all(promises)
			:andThen(function(results)
				local killers = {}
				for _, result in ipairs(results) do
					table.insert(killers, result)
				end
				resolve(killers)
			end)
			:catch(reject)
	end)
end

function KillerController:SpawnAll(spawnIndex: number): TypedPromise<{ Model }> --chaos
	local validNames = {}
	for _, name in ipairs(self:GetKillersName()) do
		if self:IsValidName(name) then
			table.insert(validNames, name)
		end
	end
	return self:SpawnKillers(validNames, spawnIndex)
end

function KillerController:SpawnKiller(name: string, spawnIndex: number): TypedPromise<Model, number>
	if name == "*" then
		error("Bulk spawn not allowed from this API.")
	elseif name == "**" then
		local pick = KillerTemplates[math.random(1, #KillerTemplates)]
		return self:_spawn(pick.Name, spawnIndex)
	else
		return self:_spawn(name, spawnIndex)
	end
end

function KillerController:GetCurrentKillers(): { Model }
	return self._killers
end

function KillerController:GetRandomIndex(): number
	local spawns = workspace.Map.spawns:GetChildren()
	return math.random(1, #spawns)
end

function KillerController:GetKillersName(): { string }
	return NAMES
end

function KillerController:IsValidName(name: string): boolean
	return table.find(NAMES, name) and name ~= "*" and name ~= "**" or false
end

function KillerController:Clear()
	self._maid:DoCleaning() -- kills every sub-maid and its clones
	table.clear(self._killers)
end

return KillerController
