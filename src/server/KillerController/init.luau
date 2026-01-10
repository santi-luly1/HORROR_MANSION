--!strict
--[=[
    Main killer controller stuff
	@class KillerController
    @author: santi-luly1

    CHANGELOG: [
		01/10/26 --> Adapted from original source.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------

local Packages = game:GetService("ReplicatedStorage").Packages

local Compute = require(script:WaitForChild("Compute"))
local Maid = require(Packages:WaitForChild("maid"))
local Promise = require(Packages:WaitForChild("promise"))
--local SpecialKillerBehaviour = require(script:WaitForChild("SpecialKillerBehaviour"))
local t = require(Packages:WaitForChild("t"))

local KillerController = {
	_init = false,
	_start = false,
}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local Killers = game:GetService("ServerStorage"):WaitForChild("Killers", 5)
local killersList = Killers:GetChildren() :: { Model }

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type TypedPromise<T> = Promise.TypedPromise<T>
local nameCheck = t.string

--------------------------------------------------------------------
--- ServiceBag (not currently using service bag)
--------------------------------------------------------------------
function KillerController:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true

	self._currentKiller = nil :: Model?
	self._maid = Maid.new()
end

function KillerController:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	self:SpawnRandomKiller():andThen(function(killer: Model)
		print(killer, killer:GetFullName())
	end):catch(warn)
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function KillerController:_spawnKillerByName(name: string): TypedPromise<Model>
	return Promise.new(function(resolve, reject, onCancel)
		if not nameCheck(name) then
			return reject(`[{script.Name}] bad argument #1 (string expected)`)
		end
		self:ClearCurrentKiller() -- just making sure, but maybe on the future there could be multiple killers at once... Interesting..

		local maid = self._maid :: Maid.Maid

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
		clone.Parent = workspace

		local hitbox = clone:FindFirstChild("hitbox") :: Part
		local running = true
		maid:GiveTask(function()
			running = false
		end)
		maid:GiveTask(hitbox.Touched:Connect(function(hit)
			local character = hit.Parent
			if character and character ~= clone then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 and not character:FindFirstAncestorOfClass("ForceField") then
					humanoid.Health = 0 -- TODO: Maybe smth else instead of just insta kill?
				end
			end
		end))
		maid:GiveTask(clone)
		self._currentKiller = clone

		maid:GiveTask(task.spawn(function()
			while running and clone.Parent do
				local ok = Compute(clone, maid) -- single path
				if not ok then
					task.wait(1)
				else
					task.wait(0.5) -- repath cadence
				end
			end
		end))

		-- TODO: Make the module "SpecialKillerBehaviour" work in here.
		return resolve(clone)
	end)
end

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------
function KillerController:SpawnRandomKiller(): TypedPromise<Model>
	local selected = killersList[math.random(1, #killersList)]
	return self:_spawnKillerByName(selected.Name)
end

function KillerController:SpawnKiller(name: string): TypedPromise<Model>
	return self:_spawnKillerByName(name)
end

function KillerController:GetCurrentKiller(): Model?
	return self._currentKiller
end

function KillerController:ClearCurrentKiller()
	self._maid:Destroy()
	self._currentKiller = nil
end

return KillerController
