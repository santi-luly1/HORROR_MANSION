import { Registry } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import KillerServiceClass from "server/services/KillerService";
import { RunService } from "@rbxts/services";
import KillerServiceNetwork from "shared/networking/KillerServiceNetwork";

const KillerService = Dependency<KillerServiceClass>();
export default (registry: Registry) => {
	if (RunService.IsServer())
		registry.RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, KillerService.GetKillersName()));
	else {
		// Cmdr will request this type on the client, so we fetch the enum list from the server.
		const enumNamesPromise = KillerServiceNetwork.Client.Get("GetKillersName").CallServerAsync();
		enumNamesPromise.andThen((enumNames) =>
			registry.RegisterType("killers", registry.Cmdr.Util.MakeEnumType(script.Name, enumNames[0])),
		);
	}
};
