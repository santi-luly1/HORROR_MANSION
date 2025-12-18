--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.HORROR_MANSION:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.HORROR_MANSION)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("HORROR_MANSIONService"))
serviceBag:Init()
serviceBag:Start()