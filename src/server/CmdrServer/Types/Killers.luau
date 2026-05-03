return function(registry)
	if game:GetService("RunService"):IsServer() then -- is this even legal? Should I be doing this????????????
		local KillerService = require("@server/KillerService")

		registry:RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, KillerService:GetKillersName()))
	else
		local KillerControllerNet = require("@network/KillerServiceNetwork")

		local enum = KillerControllerNet.GetKillersName:InvokeServer()
		registry:RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, enum))
	end
end
