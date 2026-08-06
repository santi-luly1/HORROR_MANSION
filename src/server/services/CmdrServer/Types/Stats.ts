import { Registry } from "@rbxts/cmdr";

const Type = "stats";

export = function (registry: Registry) {
	registry.RegisterType(Type, registry.Cmdr.Util.MakeEnumType(Type, ["Survivals", "Points"]));
};
