--[=[
    Client bootstrapper
	@class Client
    @author: santi-luly1

    CHANGELOG: [
		12/26/25 --> New client bootstrapper
	]
]=]

local CONTROLLERS = {
    UI = require(script.UI),
}

for name, svc in CONTROLLERS do
    assert(svc.Init, `[{script.Name}] {name} has no Init()`)
    svc:Init()
    print(`[{script.Name}] {name} initialised`)
end

for name, svc in CONTROLLERS do
    assert(svc.Start, `[{script.Name}] {name} has no Start()`)
    svc:Start()
    print(`[{script.Name}] {name} started`)
end
