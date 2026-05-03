--!strict
--[=[
	@class Server
    @author santi-luly1
    @description Server bootstrapper

    CHANGELOG: [
		12/26/25 --> New server bootstrapper
        12/31/25 --> Added proper loader
        03/01/26 --> Lighting setup and updated init loader
	]
]=]

local Lighting = game:GetService("Lighting")

local Loader = require("@packages/loader")
local Services = require("@server/Services")

-- initial set-up
Lighting.Ambient = Color3.fromRGB(0, 0, 0)

local modules = Loader.LoadChildren(script)
Services:initModules(modules):await()
Loader.SpawnAll(modules, "Start")
