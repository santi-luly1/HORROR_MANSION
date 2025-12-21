--[[
	@class ClientMain
]]
local loader = game:GetService("ReplicatedStorage"):WaitForChild("HORROR_MANSION"):WaitForChild("loader")
local require = require(loader).bootstrapGame(loader.Parent)

local serviceBag = require("ServiceBag").new()

serviceBag:GetService(require("HORROR_MANSIONServiceClient"))
serviceBag:GetService(require("ClientBootstrapService"))
serviceBag:GetService(require("CoreGui"))
serviceBag:GetService(require("ChatMessages"))
serviceBag:GetService(require("RFP"))
serviceBag:GetService(require("PlayerVisuals"))
serviceBag:GetService(require("PlayerAssign"))
serviceBag:GetService(require("OpenCoinsShop"))
serviceBag:GetService(require("PurchasingUI"))
serviceBag:GetService(require("VotingMapUI"))
serviceBag:GetService(require("SurvivedList"))
serviceBag:GetService(require("UpdateUI"))
serviceBag:GetService(require("CreatorPanel"))
serviceBag:GetService(require("ClientInit"))

serviceBag:Init()
serviceBag:Start()