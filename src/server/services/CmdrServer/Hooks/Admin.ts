import { Registry } from "@rbxts/cmdr";
import CmdrConfig from "shared/CmdrConfig";

const group = "Admin";

export = (registry: Registry) => {
	registry.RegisterHook("BeforeRun", (context) => {
		if (
			context.Group === group &&
			CmdrConfig.Permissions[group].find((id) => id === context.Executor.UserId) === undefined
		)
			return "Not authorized.";

		return undefined;
	});
};
