/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import { Trove } from "@rbxts/trove";
import simplepath from "@rbxts/simplepath";

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

// each killer gets its own entry via the model as key
const pathRegistry = new WeakMap<Model, { target?: Model; path?: simplepath }>();

export default function compute(model: Model, trove: Trove): boolean {
	const hrp = model.FindFirstChild("HumanoidRootPart") as BasePart | undefined;
	if (!hrp) {
		warn(`${model.GetFullName()} lacks HumanoidRootPart`);
		return false;
	}

	let ok = true;
	let target: Model | undefined;
	try {
		// This can fail (ej. we don't have an HRP, so it's nil, making this fail)
		// simplepath has a little flaw, when calling GetNearestCharacter, its lua version takes two arguments (self, fromPosition), so it errors out bc it tries to subtract vector and table (self)
		target = simplepath.GetNearestCharacter(hrp.Position) as Model | undefined;
	} catch {
		ok = false;
	}

	if (!ok || !target) return false;

	const human = target.FindFirstChildOfClass("Humanoid");
	if (!human || human.Health <= 0) return false;
	if (target.FindFirstChildOfClass("ForceField")) return false;

	let data = pathRegistry.get(model);
	if (!data) {
		data = { target: undefined, path: undefined };
		pathRegistry.set(model, data);

		trove.add(() => {
			if (data && data.path && typeIs(data.path.Destroy, "function")) {
				data.path.Destroy();
			}
			pathRegistry.delete(model);
		});
	}

	if (target !== data.target || !data.path) {
		data.target = target;
		data.path = new simplepath(model, {
			AgentHeight: 5,
			AgentRadius: 2,
			AgentCanJump: true,
			Costs: { Roof: math.huge },
		});
	}

	try {
		const result = data.path.Run(target.GetPivot().Position) as boolean;
		return result;
	} catch {
		return false;
	}
}
