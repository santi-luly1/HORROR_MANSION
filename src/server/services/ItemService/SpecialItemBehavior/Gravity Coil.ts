// --<<SERVER>>--
import Default from "./Default";
import { Trove } from "@rbxts/trove";

const GravityAccelerationConstant = 9.81 * 20; // For every 20 studs is one meter on ROBLOX. 9.81 is the common accepted acceleration of gravity per a kg on earth, and is used on ROBLOX
const PercentGravity = 0.25; // Percentage of countered acceleration due to gravity by the coil.

// @author Quenty
// A rewritten gravity coil script designed for understanding and reliability

function CallOnChildren(Instance: Instance, FunctionToCall: (i: Instance) => void): void {
	// Calls a function on each of the children of a certain object, using recursion.

	FunctionToCall(Instance);

	for (const Child of Instance.GetChildren()) CallOnChildren(Child, FunctionToCall);
}

function GetBricks(StartInstance: Instance): BasePart[] {
	// Returns a list of bricks (will include StartInstance)

	const List = {} as BasePart[];

	CallOnChildren(StartInstance, (Item) => {
		if (Item.IsA("BasePart")) List.push(Item as BasePart);
	});

	return List;
}

export default class GravityCoil extends Default {
	private antiGravityForce?: BodyForce;
	private coilSound?: Sound;
	private handle?: Part;

	public Setup(): void {
		// [MODIFIED]
		const AntiGravityForce = new Instance("BodyForce") as BodyForce;
		AntiGravityForce.Name = "GravityCoilEffect";
		AntiGravityForce.Archivable = false;
		this.antiGravityForce = AntiGravityForce;

		const Handle = this.tool.FindFirstChild("Handle") as Part;
		this.handle = Handle;

		const CoilSound = new Instance("Sound") as Sound;
		CoilSound.Name = "CoilSound";
		CoilSound.SoundId = "rbxassetid://84428884917597";
		CoilSound.Parent = Handle;
		this.coilSound = CoilSound;

		const functionUpdateGravityEffect = (Character: Model) => {
			// Updates the AntiGravityForce to match the force of gravity on the character

			let Bricks: BasePart[];
			const hrp = Character.FindFirstChild("HumanoidRootPart") as Part | undefined;
			if (Character.IsDescendantOf(game) && hrp && hrp.IsA("BasePart")) {
				const BasePart = hrp as BasePart;
				Bricks = BasePart.GetConnectedParts(true) as BasePart[]; // Recursive
			} else {
				warn("[UpdateGravityEffect] - Character failed to have a HumanoidRootPart or something");
				Bricks = GetBricks(Character);
			}

			let TotalMass = 0;

			// Calculate total mass of player
			for (const Part of Bricks) TotalMass = TotalMass + Part.GetMass();

			// Force = Mass * Acceleration
			const ForceOnCharacter = GravityAccelerationConstant * TotalMass;
			const CounteringForceMagnitude = (1 - PercentGravity) * ForceOnCharacter;

			// Set the actual value...
			AntiGravityForce.Force = new Vector3(0, CounteringForceMagnitude, 0);
		};

		// Connect events for player interaction
		const innerTrove = new Trove();
		this.trove.add(innerTrove);

		this.trove.add(
			this.tool.Equipped.Connect(() => {
				const player = this.GetPlayerFromEquipped();
				const Character = player?.Character;

				if (Character) {
					// Connect events to recalculate gravity when hats are added or removed. Of course, this is not a perfect solution,
					// as connected parts are not necessarily part of the character, but ROBLOX has no API to handle the changing of joints, and
					// scanning the whole game for potential joints is really not worth the efficiency cost.
					innerTrove.clean();

					innerTrove.add(
						Character.DescendantAdded.Connect(() => {
							functionUpdateGravityEffect(Character);
						}),
					);

					innerTrove.add(
						Character.DescendantRemoving.Connect(() => {
							functionUpdateGravityEffect(Character);
						}),
					);

					functionUpdateGravityEffect(Character);
					// Add in the force
					AntiGravityForce.Parent = Handle;

					// Play sound
					CoilSound.Play();
				} else {
					warn("[GravityCoil] - Somehow inexplicity failed to retrieve character");
				}
			}),
		);

		this.trove.add(
			this.tool.Unequipped.Connect(() => {
				// Remove force and clean up events
				AntiGravityForce.Parent = undefined;
				CoilSound.Stop();
			}),
		);
	}
}
