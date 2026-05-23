/*
[=[
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
*/

import { Loader } from "@rbxts/loader"
import { Lighting } from "@rbxts/services"

const modules = script.Parent?.Parent?.FindFirstChild("Services") as Folder;

// initial set-up
Lighting.Ambient = Color3.fromRGB(0, 0, 0)

Loader.Load(modules)
Services.initModules(modules).await()
Loader.SpawnAll(modules, "Start")
