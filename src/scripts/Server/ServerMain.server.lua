--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.HORROR_MANSION:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.HORROR_MANSION)

local serviceBag = require("ServiceBag").new()

serviceBag:GetService(require("HORROR_MANSIONService"))
serviceBag:GetService(require("GameSettings"))
serviceBag:GetService(require("KillersController"))
serviceBag:GetService(require("GameFunctions"))
serviceBag:GetService(require("GameLogic"))
serviceBag:GetService(require("DataStores"))
serviceBag:GetService(require("Assign"))
serviceBag:GetService(require("PurchasedCoinsGiver"))

serviceBag:Init()
serviceBag:Start()