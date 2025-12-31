local require = (require :: any)(script.Parent.loader).load(script)

local GameFunctions = {}
GameFunctions.ServiceName = "GameFunctions"

local _serviceBag
local Settings
local KillersController
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function GameFunctions:Init(serviceBag)
	_serviceBag = assert(serviceBag, "No serviceBag provided")
	Settings = _serviceBag:GetService(require("GameSettings")).Main
	KillersController = _serviceBag:GetService(require("KillersController"))
end

function GameFunctions.chooseRandomSpawn(killer)
	if not killer then
		return
	end
	local map = Settings.Map
	if not map or not map:FindFirstChild("Map") then
		return
	end
	local spawnsFolder = map.Map:FindFirstChild("Spawns")
	if not spawnsFolder or not spawnsFolder:FindFirstChild("Killers") then
		return
	end
	local Spawns = spawnsFolder.Killers:GetChildren()
	if #Spawns == 0 then
		return
	end
	local Selected = math.random(1, #Spawns)
	local tp_CFrame = Spawns[Selected].CFrame
	local TeleportPart = killer:FindFirstChild("HumanoidRootPart")
		or killer:FindFirstChild("Torso")
		or killer:FindFirstChild("UpperTorso")
		or killer:FindFirstChild("Head")
	if TeleportPart then
		TeleportPart.CFrame = tp_CFrame
	end
end

function GameFunctions.chooseRandomKiller()
	Settings.Killer = KillersController:SpawnRandomKiller()
	return Settings.Killer
end

function GameFunctions.startGame()
	-- Lightweight orchestrator: spawn killer and notify clients via RemoteEvent if available.
	local killer = GameFunctions.chooseRandomKiller()
	if killer then
		ReplicatedStorage.RemoteEvents.SendChatMessages:FireAllClients(killer.Name)
	end
end

function GameFunctions.endGame()
	-- Lightweight end: clear active killers via KillersController and notify clients.
	KillersController:Clear()
	ReplicatedStorage.RemoteEvents.GameEnded:FireAllClients()
end

return GameFunctions
