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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages

local Loader = require(Packages:WaitForChild("loader"))
local Controllers = require(script:WaitForChild("Controllers"))

local modules = Loader.LoadChildren(script)
Controllers.initModules(modules, "Init"):await()
Loader.SpawnAll(modules, "Start")
