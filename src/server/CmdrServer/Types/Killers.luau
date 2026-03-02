return function(registry)
	if game:GetService("RunService"):IsServer() then -- is this even legal? Should I be doing this????????????
		local ServerScriptService = game:GetService("ServerScriptService")
		local KillerController = require(ServerScriptService.Server.KillerController)

		registry:RegisterType(
			"killers",
			registry.Cmdr.Util.MakeEnumType(script.Name, KillerController:GetKillersName())
		)
	else
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local KillerControllerNet = require(ReplicatedStorage.Network.KillerControllerNetwork)

		local enum = KillerControllerNet.GetKillersName:InvokeServer()
		registry:RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, enum))
	end
end
