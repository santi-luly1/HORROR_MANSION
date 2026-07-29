// --!strict
// --<<SERVER>>--
import { Debris, Workspace } from "@rbxts/services";
import Default from "./Default";

const Speed = 100;
const Duration = 9999999;
const NozzleOffset = new Vector3(0, 0.4, -1.1);

const BreakJoints = (Object: Instance) => {
	if (!Object.IsA("BasePart")) {
		for (const OtherObject of Object.GetDescendants()) {
			BreakJoints(OtherObject);
		}
	} else {
		for (const Joint of Object.GetJoints()) {
			Joint.Destroy();
		}
	}
};

const createSound = (name: string, id: string, handle: Part): Sound => {
	const sound = new Instance("Sound");
	sound.Name = name;
	sound.SoundId = id;
	sound.Parent = handle;
	return sound;
};

export default class HyperlaserGun extends Default {
	private readonly Speed = Speed;
	private readonly Duration = Duration;
	private readonly NozzleOffset = NozzleOffset;

	private Handle: Part;
	private Sounds!: {
		Fire: Sound;
		Reload: Sound;
		HitFade: Sound;
	};

	private ServerControl: RemoteFunction;
	private ClientControl: RemoteFunction;

	public constructor(tool: Tool) {
		super(tool);

		const handle = this.tool.FindFirstChild("Handle") as Part | undefined;
		if (!handle) {
			throw "Missing Handle";
		}
		this.Handle = handle;

		this.ServerControl = new Instance("RemoteFunction");
		this.ServerControl.Name = "ServerControl";
		this.ServerControl.Parent = this.tool;

		this.ClientControl = new Instance("RemoteFunction");
		this.ClientControl.Name = "ClientControl";
		this.ClientControl.Parent = this.tool;

		this.Sounds = {
			Fire: createSound("Fire", "rbxassetid://130113322", this.Handle),
			Reload: createSound("Reload", "rbxassetid://130113370", this.Handle),
			HitFade: createSound("HitFade", "rbxassetid://130113415", this.Handle),
		};
	}

	public Setup(): void {
		let toolCharacter: Model | undefined;
		let toolHumanoid: Humanoid | undefined;

		const InvokeClient = (mode: string, value: unknown) => {
			pcall(() => {
				const plr = this.GetPlayerFromEquipped();
				if (!plr) return;
				this.ClientControl.InvokeClient(plr, mode, value);
			});
		};

		const FindCharacterAncestor = (parent: Instance): [Model | undefined, Humanoid | undefined] => {
			if (parent && parent !== Workspace) {
				const humanoid = parent.FindFirstChildOfClass("Humanoid") as Humanoid | undefined;
				if (humanoid) {
					return [parent as Model, humanoid];
				}
				const next = parent.Parent;
				if (!next) return [undefined, undefined];
				return FindCharacterAncestor(next);
			}
			return [undefined, undefined];
		};

		const GetTransparentsRecursive = (parent: Instance, parts: Instance[] = []): Instance[] => {
			for (const v of parent.GetChildren()) {
				if (v.IsA("BasePart") || v.IsA("Decal") || v.IsA("Texture")) {
					parts.push(v);
				}
				GetTransparentsRecursive(v, parts);
			}
			return parts;
		};

		const SelectionBoxify = (Object: Instance) => {
			const SelectionBox = new Instance("SelectionBox");
			SelectionBox.Adornee = Object;
			SelectionBox.Color3 = Color3.fromRGB(0, 255, 255);
			SelectionBox.Parent = Object;
			return SelectionBox;
		};

		const Light = (Object: Instance) => {
			const light = this.Handle.FindFirstChild("PointLight") as PointLight | undefined;
			if (!light) return;
			const newLight = light.Clone();
			newLight.Range = newLight.Range + 2;
			newLight.Parent = Object;
		};

		const FadeOutObjects = (Objects: Instance[], FadeIncrement: number) => {
			let LastObject: BasePart | Decal | Texture | undefined;
			do {
				LastObject = undefined;
				for (const v of Objects) {
					if (v.IsA("BasePart") || v.IsA("Decal") || v.IsA("Texture")) {
						(v as BasePart | Decal | Texture).Transparency += FadeIncrement;
						LastObject = v as BasePart | Decal | Texture;
					}
				}
				task.wait();
			} while (!!LastObject && LastObject.Transparency < 1);
		};

		const Dematerialize = (char: Model, humanoid: Humanoid, FirstPart: BasePart) => {
			humanoid.WalkSpeed = 0;

			const Parts: BasePart[] = [];

			for (const v of char.GetChildren()) {
				if (v.IsA("BasePart")) {
					(v as BasePart).Anchored = true;
					Parts.push(v as BasePart);
				} else if (v.IsA("LocalScript") || v.IsA("Script")) {
					v.Destroy();
				}
			}

			const SelectionBoxes: Instance[] = [];

			const FirstSelectionBox = SelectionBoxify(FirstPart);
			Light(FirstPart);
			task.wait();

			for (const v of Parts) {
				if (v !== FirstPart) {
					SelectionBoxes.push(SelectionBoxify(v));
					Light(v);
				}
			}

			const ObjectsWithTransparency = GetTransparentsRecursive(char);
			FadeOutObjects(ObjectsWithTransparency, 0.1);

			task.wait(0.5);

			BreakJoints(char);
			humanoid.Health = 0;

			Debris.AddItem(char, 2);

			const FadeIncrement = 0.05;
			task.delay(0.2, () => {
				FadeOutObjects([FirstSelectionBox], FadeIncrement);
				if (char && char.Parent) char.Destroy();
			});
			FadeOutObjects(SelectionBoxes, FadeIncrement);
		};

		const Touched = (Projectile: BasePart | undefined, hit: BasePart) => {
			if (!hit.Parent) return;

			const character = hit.Parent as Model;
			const humanoid = character.FindFirstChild("Humanoid") as Humanoid | undefined;

			if (character && humanoid && character !== toolCharacter) {
				let forceFieldExists = false;
				for (const v of character.GetChildren()) {
					if (v.IsA("ForceField")) {
						forceFieldExists = true;
						break;
					}
				}

				if (!forceFieldExists) {
					if (Projectile) {
						const HitFadeSound = Projectile.FindFirstChild(this.Sounds.HitFade.Name) as Sound | undefined;
						const torso = character.FindFirstChild("Torso") ?? character.FindFirstChild("HumanoidRootPart");
						if (HitFadeSound && torso) {
							HitFadeSound.Parent = torso;
							HitFadeSound.Play();
						}
					}
					Dematerialize(character, humanoid, hit);
				}

				if (Projectile && Projectile.Parent) Projectile.Destroy();
			}
		};

		const BaseShot = new Instance("Part");
		BaseShot.Name = "Effect";
		BaseShot.BrickColor = new BrickColor("Toothpaste");
		BaseShot.Material = Enum.Material.Plastic;
		BaseShot.Shape = Enum.PartType.Block;
		BaseShot.TopSurface = Enum.SurfaceType.Smooth;
		BaseShot.BottomSurface = Enum.SurfaceType.Smooth;
		BaseShot.Size = new Vector3(0.2, 0.2, 3);
		BaseShot.CanCollide = false;
		BaseShot.Locked = true;
		SelectionBoxify(BaseShot);
		Light(BaseShot);

		const BaseShotSound = this.Sounds.HitFade.Clone();
		BaseShotSound.Parent = BaseShot;

		const Activated = (target: Vector3) => {
			if (!this.tool.Enabled) return;
			if (!toolHumanoid || toolHumanoid.Health <= 0) return;

			this.tool.Enabled = false;

			InvokeClient("PlaySound", this.Sounds.Fire);

			const HandleCFrame = this.Handle.CFrame;
			const FiringPoint = HandleCFrame.Position.add(HandleCFrame.VectorToWorldSpace(this.NozzleOffset));
			const ShotCFrame = CFrame.lookAt(FiringPoint, target);

			const LaserShotClone = BaseShot.Clone();
			LaserShotClone.CFrame = ShotCFrame.mul(new CFrame(0, 0, 0)).add(
				ShotCFrame.LookVector.mul(BaseShot.Size.Z / 2),
			);

			const BodyVelocity = new Instance("BodyVelocity");
			BodyVelocity.Velocity = ShotCFrame.LookVector.mul(this.Speed);
			BodyVelocity.Parent = LaserShotClone;

			this.trove.add(
				LaserShotClone.Touched.Connect((Hit) => {
					if (!Hit || !Hit.Parent) return;
					Touched(LaserShotClone, Hit);
				}),
			);

			Debris.AddItem(LaserShotClone, this.Duration);
			LaserShotClone.Parent = Workspace;

			task.wait(0);

			InvokeClient("PlaySound", this.Sounds.Reload);

			task.wait(0);

			this.tool.Enabled = true;
		};

		this.ServerControl.OnServerInvoke = (plr: Player, ...args: unknown[]) => {
			if (
				plr !== this.GetPlayerFromEquipped() ||
				!toolHumanoid ||
				toolHumanoid.Health === 0 ||
				!this.tool.Enabled
			)
				return;

			const [Mode, Value, arg] = args as [string, unknown, unknown];
			if (Mode === "Click" && Value) {
				Activated(arg as Vector3);
			}
		};

		this.trove.add(
			this.tool.Equipped.Connect(() => {
				toolCharacter = this.tool.Parent as Model;
				toolHumanoid = toolCharacter?.FindFirstChildOfClass("Humanoid") as Humanoid | undefined;
			}),
		);

		this.trove.add(
			this.tool.Unequipped.Connect(() => {
				toolCharacter = undefined;
				toolHumanoid = undefined;
			}),
		);
	}
}
