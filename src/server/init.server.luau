--[=[
    Server bootstrapper
	@class Server
    @author: santi-luly1

    CHANGELOG: [
		12/26/25 --> New server bootstrapper
        12/31/25 --> Added proper loader
	]

    FIXME: currently, every module loads one by one, and if some yield (ej WaitForChild), the runtime won';t continue, same goes to the client.
    future me, consider adding a task.spawn, modify the laoder module or get another module.
]=]

local Packages = game:GetService("ReplicatedStorage").Packages

local Loader = require(Packages:WaitForChild("loader"))

Loader.SpawnAll(Loader.LoadChildren(script), "Init")
Loader.SpawnAll(Loader.LoadChildren(script), "Start")
