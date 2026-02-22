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
		02/15/26 --> Added SpecialKillerBehavior support and removed sounds index.
		02/21/26 --> Fixed SpawnAll, it was failing for the slightest rejection.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networking = ReplicatedStorage:WaitForChild("Network")

local Maid = require(Packages:WaitForChild("maid"))
local Promise = require(Packages:WaitForChild("promise"))
local Signal = require(Packages:WaitForChild("signal"))
local SpecialKillerBehavior = require(script:WaitForChild("SpecialKillerBehavior"))
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
	SpecialKillerBehavior:Init()

	-- handle client requests
	KillerControllerNet.GetKillersName.OnServerInvoke = function()
		return self:GetKillersName()
	end
end

function KillerController:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	math.randomseed(os.clock())
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
			return reject(`Name '{name}' is invalid`)
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

		local behaviour = SpecialKillerBehavior:Get(name)
		local Compute = require(script:WaitForChild("Compute"))
		local clone = template:Clone()

		local hrp = clone:FindFirstChild("HumanoidRootPart") :: Part
		local hitbox = clone:FindFirstChild("hitbox") :: Part
		local humanoid = clone:FindFirstChild("Humanoid") :: Humanoid
		local index, cf = getSpawnCFrame(spawnIndex)
		clone.Parent = workspace
		hrp.CFrame = cf
		clone:SetAttribute("killer", true)

		maid:GiveTask(clone)
		maid:LinkToInstance(clone) -- would this be an issue with the line above?

		for _, existing in ipairs(self._killers) do
			if existing ~= clone and existing.Name == name and existing.Parent then
				clone:Destroy()
				return reject(`Killer '{name}' already spawned`) --maybe shoudl I allow this?
			end
		end
		table.insert(self._killers, clone)

		behaviour:Init(clone, maid)

		hitbox.Transparency = 0.8
		local canHit = true -- typical debounce
		maid:GiveTask(hitbox.Touched:Connect(function(hit)
			local char = hit.Parent :: Model
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if
				canHit
				and hum
				and hum.Health > 0
				and not char:FindFirstChildOfClass("ForceField")
				and not char:GetAttribute("killer")
			then
				canHit = false

				local track = Instance.new("Sound")
				track.Parent = hrp
				track.Volume = 0.5
				track.Ended:Once(function()
					track:Destroy()
				end)
				track.SoundId = behaviour:GetBonkSound()
				track:Play()

				behaviour:Damage(clone, hum)
				task.delay(behaviour:GetBonkDelay(), function()
					canHit = true
				end)
			end
		end))

		humanoid.Died:Once(function()
			maid:Destroy()
		end)
		maid:GiveTask(humanoid.HealthChanged:Connect(function(health)
			behaviour:OnDamaged(health)
		end))

		maid:GiveTask(behaviour:InitAI(clone, maid, Compute))

		maid:GiveTask(function()
			local idx = table.find(self._killers, clone)
			if idx then
				table.remove(self._killers, idx)
				self.KillerCleared:Fire(clone.Name)
			end
		end)

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
			spawnIndex = spawnIndex > 0 and spawnIndex or self:GetRandomIndex()
			if self:IsValidName(name) then
				local wrapped = self:SpawnKiller(name, spawnIndex)
					:andThen(function(model)
						return { ok = true, result = model }
					end)
					:catch(function(err)
						return { ok = false, result = err }
					end)
				table.insert(promises, wrapped)
			end
		end

		if #promises == 0 then
			return reject("No valid killers to spawn")
		end

		Promise.all(promises)
			:andThen(function(results)
				local killers = {}
				local errors = {}

				for _, result in ipairs(results) do
					table.insert(result.ok and killers or errors, result.result)
				end

				return #killers > 0 and resolve(killers)
					or reject(`All {#errors} killer spawns failed: {table.concat(errors, ", ")}`)
			end)
			:catch(warn)
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
	-- "*" = all "**" = random
	return table.find(NAMES, name) and name ~= "*" and name ~= "**" or false
end

function KillerController:Clear()
	self._maid:DoCleaning() -- kills every sub-maid and its clones
	table.clear(self._killers)
end

return KillerController
