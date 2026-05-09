--[=[
    Client bootstrapper
	@class Client
    @author: santi-luly1

    CHANGELOG: [
		12/26/25 --> New client bootstrapper
        12/31/25 --> Added proper loader
		03/01/25 --> Updated init loader
	]
]=]

local Controllers = require("@self/Controllers")
local Loader = require("@game/ReplicatedStorage/Packages/loader")

local modules = Loader.LoadChildren(script)
Controllers:initModules(modules):await()
Loader.SpawnAll(modules, "Start")
