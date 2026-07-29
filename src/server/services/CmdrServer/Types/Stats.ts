import { Registry } from "@rbxts/cmdr";

export default (registry: Registry) => {
	registry.RegisterType("stats", registry.Cmdr.Util.MakeEnumType(script.Name, ["Survivals", "Points"]));
};
