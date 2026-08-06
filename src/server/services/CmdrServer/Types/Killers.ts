import { Registry } from "@rbxts/cmdr";
import { Dependency } from "@flamework/core";

import KillerServiceClass from "server/services/KillerService";
import { RunService } from "@rbxts/services";
import KillerServiceNetwork from "shared/networking/KillerServiceNetwork";

const Type = "killers";

export = function (registry: Registry) {
	const KillerService = Dependency<KillerServiceClass>();

	if (RunService.IsServer())
		registry.RegisterType(Type, registry.Cmdr.Util.MakeEnumType(Type, KillerService.GetKillersName()));
	else {
		// Cmdr will request this type on the client, so we fetch the enum list from the server.
		const enumNamesPromise = KillerServiceNetwork.Client.Get("GetKillersName").CallServerAsync();
		enumNamesPromise.andThen((enumNames) =>
			registry.RegisterType(Type, registry.Cmdr.Util.MakeEnumType(Type, enumNames[0])),
		);
	}
};
