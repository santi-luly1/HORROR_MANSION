--!strict
--[=[
    Server bootstrapper
	@class Server
    @author: santi-luly1

    CHANGELOG: [
		12/26/25 --> New server bootstrapper
        12/31/25 --> Added proper loader
        03/01/26 --> Lighting setup and updated init loader
	]
]=]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages

local Loader = require(Packages:WaitForChild("loader"))
local Services = require(script:WaitForChild("Services"))

-- initial set-up
Lighting.Ambient = Color3.fromRGB(0, 0, 0)

local modules = Loader.LoadChildren(script)
Services.initModules(modules, "Init"):await()
Loader.SpawnAll(modules, "Start")
