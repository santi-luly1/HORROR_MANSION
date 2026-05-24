--!strict
--[=[
	@class KillerService
    @author a
    @description Main API for killer(s) management
	@note as I added OOP killers, I also removed the second arguments from promises (spawnIndex), so I need to implement them into the Killer's class

    CHANGELOG: [
		01/10/26 --> Adapted from original source.
		01/11/26 --> Added module-wide typechecking and random spawn selector with its APIs.
		01/28/26 --> Added multiple killers support and signals.
		01/30/26 --> Added GetRandomSpawnIndex API, and added killer sounds.
		02/15/26 --> Added SpecialKillerBehavior support and removed sounds index.
		02/21/26 --> Fixed SpawnAll, it was failing for the slightest rejection.
		03/13/26 --> Added spawn lock to prevent concurrent duplicate killer spawns (AI).
		04/11/26 --> Re-organized the public API to make it more "human-readable" (was hurting my eyes and brain).
		04/17/26 --> Added GetKillerInRound API.
		04/25/26 --> Added a delay before deleting the killer's model, and made the module to be OOP instead (..too much?).
		05/06/26 --> Moved humanoid-related stuff into KillerClass to handle.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
-- Roblox services
local ServerStorage = game:GetService("ServerStorage")

-- Packages
local Maid = require("@game/ReplicatedStorage/Packages/maid")
local Promise = require("@game/ReplicatedStorage/Packages/promise")
local Signal = require("@game/ReplicatedStorage/Packages/signal")
local t = require("@game/ReplicatedStorage/Packages/t")

-- Types
local Types = require("@game/ServerScriptService/Server/Types/KillerServiceTypes")

-- Networking
local Networking = require("@game/ReplicatedStorage/Network/KillerServiceNetwork")

-- Local utilities
local SpecialKillerBehavior = require("@self/SpecialKillerBehavior")

-- Services

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local KillerService = {
	_init = false,
	_start = false,
	_killers = {},
	_spawningNames = {}, -- db-lock like
} :: Types.KillerService

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local KillerClass = require("@self/KillerClass")
local KillersFolder = ServerStorage:WaitForChild("Killers", 5)
local KillerTemplates = KillersFolder:GetChildren() :: { Model }

local NAMES = table.create(#KillerTemplates + 2, "*")
do
	NAMES[2] = "**"
	for i, m in KillerTemplates do
		NAMES[i + 2] = m.Name
	end
end

local spawnCheck = t.tuple(t.string, t.number)

--------------------------------------------------------------------
--- Init / Start
--------------------------------------------------------------------
function KillerService:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	self._maid = Maid.new()
	self.KillerSpawned = Signal.new()
	self.KillerCleared = Signal.new()
	SpecialKillerBehavior:Init()

	-- handle client requests
	Networking.GetKillersName.OnServerInvoke = function()
		return self:GetKillersName()
	end
end

function KillerService:Start()
	assert(self._init, `[{script.Name}] - Module not initialized.`)
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	math.randomseed(os.clock())
end

--------------------------------------------------------------------
--- Helpers
--------------------------------------------------------------------
local function getSpawnCFrame(index: number): CFrame
	local spawns = workspace.Map.spawns:GetChildren() :: { SpawnLocation }
	return spawns[index].CFrame * CFrame.new(0, 10, 0)
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------
function KillerService:_spawn(name: string, spawnIndex: number): Types.TypedPromise<Types.Killer>
	return Promise.new(function(resolve, reject, onCancel)
		if not spawnCheck(name, spawnIndex) then
			return reject(`[{script.Name}] bad argument(s)`)
		end

		if not self:IsValidName(name) then
			return reject(`Name '{name}' is invalid`)
		end

		if self._spawningNames[name] then
			return reject(`Killer '{name}' spawn already in progress`)
		end
		self._spawningNames[name] = true

		local function releaseSpawnLock()
			self._spawningNames[name] = nil
		end

		spawnIndex = spawnIndex > 0 and spawnIndex or self:GetRandomSpawnIndex()

		local maid = Maid.new()

		if onCancel(function()
			releaseSpawnLock()
			maid:Destroy()
		end) then
			return
		end

		local template = KillersFolder:FindFirstChild(name)
		if not template then
			releaseSpawnLock()
			return reject("Killer not found")
		end

		local clone = template:Clone()
		clone.Parent = workspace

		local behavior = SpecialKillerBehavior:Get(name)
		local killer = KillerClass.new(clone, maid)
		killer.id = #self._killers + 1 -- should be handled by the class instead?
		killer.behavior = behavior:new(killer)

		table.insert(self._killers, killer)

		killer:TeleportTo(getSpawnCFrame(spawnIndex))

		killer.behavior:Setup()

		maid:GiveTask(function()
			local idx = table.find(self._killers, killer)
			if idx then
				table.remove(self._killers, idx)
				self.KillerCleared:Fire(killer.name)
			end
		end)

		self._maid:GiveTask(maid)
		self.KillerSpawned:Fire(killer)
		releaseSpawnLock()
		return resolve(killer)
	end)
end

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
function KillerService:GetRandomSpawnIndex(): number
	local spawns = workspace.Map.spawns:GetChildren()
	return math.random(1, #spawns)
end

function KillerService:GetKillersName(): { string }
	return NAMES
end

function KillerService:GetKillerInRound(
	name: string
): { Types.Killer }? -- FIXME: a little missleading that name not being in prural.
	local killers = {}
	for _, k in ipairs(self._killers) do
		if k.name == name then
			table.insert(killers, k)
		end
	end

	return killers
end

function KillerService:IsValidName(name: string, includeSpecial: boolean?): boolean
	if includeSpecial then
		return table.find(NAMES, name) ~= nil
	end

	return table.find(NAMES, name) ~= nil and name ~= "*" and name ~= "**"
end

function KillerService:GetCurrentKillers(): { Types.Killer }
	return self._killers
end

function KillerService:Clear()
	self._maid:DoCleaning() -- kills every sub-maid and its clones
	table.clear(self._killers)
end

function KillerService:SpawnKiller(name: string, spawnIndex: number): Types.TypedPromise<Types.Killer>
	if name == "*" then
		error("Bulk spawn not allowed from this API.")
	elseif name == "**" then
		local pick = KillerTemplates[math.random(1, #KillerTemplates)]
		return self:_spawn(pick.Name, spawnIndex)
	else
		return self:_spawn(name, spawnIndex)
	end
end

function KillerService:SpawnKillers(names: { string }, spawnIndex: number): Types.TypedPromise<{ Types.Killer }>
	local promises = {} -- valid killers to spawn

	for _, name in ipairs(names) do
		-- spawnIndex = spawnIndex > 0 and spawnIndex or self:GetRandomSpawnIndex() -- _spawn() already handles this..
		if self:IsValidName(name) then
			table.insert(
				promises,
				self:SpawnKiller(name, spawnIndex)
					:andThen(function(model)
						return { ok = true, result = model }
					end)
					:catch(function(err)
						return { ok = false, result = tostring(err) }
					end)
			)
		end
	end

	if #promises == 0 then
		return Promise.reject("No valid killers to spawn")
	end

	return Promise.all(promises):andThen(function(results)
		local killers = {}
		local errors = {}

		for _, r in ipairs(results) do
			if r.ok then
				table.insert(killers, r.result)
			else
				table.insert(errors, r.result)
			end
		end

		if #killers > 0 then -- this section could be shorter, just let it be simple for now.
			return killers
		else
			return Promise.reject(`All {#errors} killer spawns failed: {table.concat(errors, ", ")}`)
		end
	end)
end

function KillerService:SpawnAll(spawnIndex: number): Types.TypedPromise<{ Types.Killer }>
	local validNames = {}

	for _, name in ipairs(self:GetKillersName()) do
		if self:IsValidName(name) then
			table.insert(validNames, name)
		end
	end

	if #validNames == 0 then
		return Promise.reject("No valid killers available to spawn")
	end

	return self:SpawnKillers(validNames, spawnIndex)
end

return KillerService
