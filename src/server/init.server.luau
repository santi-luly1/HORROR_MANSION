--!strict
--[=[
	@class Server
    @author santi-luly1
    @description Server bootstrapper
    @note Project probably will be migrated to robloxts, just have to do some research first,
        while also updating into a new project structure.

    CHANGELOG: [
		12/26/25 --> New server bootstrapper
        12/31/25 --> Added proper loader
        03/01/26 --> Lighting setup and updated init loader
	]
]=]

local Lighting = game:GetService("Lighting")

local Loader = require("@game/ReplicatedStorage/Packages/loader")
local Services = require("@self/Services")

-- initial set-up
Lighting.Ambient = Color3.fromRGB(0, 0, 0)

local modules = Loader.LoadChildren(script)
Services:initModules(modules):await()
Loader.SpawnAll(modules, "Start")
