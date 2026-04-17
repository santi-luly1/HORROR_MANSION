return function(registry)
	if game:GetService("RunService"):IsServer() then -- is this even legal? Should I be doing this????????????
		local ServerScriptService = game:GetService("ServerScriptService")
		local KillerService = require(ServerScriptService.Server.KillerService)

		registry:RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, KillerService:GetKillersName()))
	else
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local KillerControllerNet = require(ReplicatedStorage.Network.KillerServiceNetwork)

		local enum = KillerControllerNet.GetKillersName:InvokeServer()
		registry:RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, enum))
	end
end
