--[=[
    Server bootstrapper
	@class Server
    @author: santi-luly1

    CHANGELOG: [
		12/26/25 --> New server bootstrapper
	]
]=]

local SERVICES = {
    DataStores = require(script.DataStores),
}

for name, svc in SERVICES do
    assert(svc.Init, `[{script.Name}] {name} has no Init()`)
    svc:Init()
    print(`[{script.Name}] {name} initialised`)
end

for name, svc in SERVICES do
    assert(svc.Start, `[{script.Name}] {name} has no Start()`)
    svc:Start()
    print(`[{script.Name}] {name} started`)
end
