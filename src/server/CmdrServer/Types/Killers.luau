return function(registry)
	if game:GetService("RunService"):IsServer() then -- is this even legal? Should I be doing this????????????
		local KillerService = require("@game/ServerScriptService/Server/KillerService")

		registry:RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, KillerService:GetKillersName()))
	else
		local KillerControllerNet = require("@game/ReplicatedStorage/Network/KillerServiceNetwork")

		local enum = KillerControllerNet.GetKillersName:InvokeServer()
		registry:RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, enum))
	end
end
