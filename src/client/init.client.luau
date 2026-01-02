--[=[
    Client bootstrapper
	@class Client
    @author: santi-luly1

    CHANGELOG: [
		12/26/25 --> New client bootstrapper
        12/31/25 --> Added proper loader
	]
]=]

local Packages = game:GetService("ReplicatedStorage").Packages

local Loader = require(Packages:WaitForChild("loader"))

Loader.SpawnAll(Loader.LoadChildren(script), "Init")
Loader.SpawnAll(Loader.LoadChildren(script), "Start")
