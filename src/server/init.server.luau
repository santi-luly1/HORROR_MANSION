--[=[
    Server bootstrapper
	@class Server
    @author: santi-luly1

    CHANGELOG: [
		12/26/25 --> New server bootstrapper
        12/31/25 --> Added proper loader
	]

    NOTE > maybe I should consider requireing all of the modules inside an "Services" module or smth, feel like cacheing the
    modules would improve performance and reduce bugs (vars would initialize just once)
]=]

local Packages = game:GetService("ReplicatedStorage").Packages

local Loader = require(Packages:WaitForChild("loader"))

Loader.SpawnAll(Loader.LoadChildren(script), "Init")
Loader.SpawnAll(Loader.LoadChildren(script), "Start")
