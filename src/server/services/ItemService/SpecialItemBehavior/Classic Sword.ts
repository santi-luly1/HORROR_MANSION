// --<<SERVER>>--
import { Debris, Players, RunService } from "@rbxts/services";
import Default from "./Default";

const DamageValues = {
	BaseDamage: 5,
	SlashDamage: 10,
	LungeDamage: 30,
};

// For R15 avatars
const Animations = {
	R15Slash: 522635514,
	R15Lunge: 522638767,
};

const Grips = {
	Up: new CFrame(0, 0, -1.70000005, 0, 0, 1, 1, 0, 0, 0, 1, 0),
	Out: new CFrame(0, 0, -1.70000005, 0, 1, 0, 1, -0, 0, 0, 0, -1),
};

export default class ClassicSword extends Default {
	private Damage = DamageValues.BaseDamage;
	private ToolEquipped = false;
	private LastAttack = 0;
	private Connection: RBXScriptConnection | undefined;

	private Handle: Part;
	private Sounds: {
		Slash: Sound;
		Lunge: Sound;
		Unsheath: Sound;
	};
	private R15SlashAnim: Animation;
	private R15LungeAnim: Animation;

	private Character?: Model;
	private Humanoid?: Humanoid;
	private Torso?: BasePart;

	constructor(tool: Tool) {
		super(tool);

		this.Handle = (this.tool.FindFirstChild("Handle") as Part)!;

		const createSound = (name: string, id: number): Sound => {
			const sound = new Instance("Sound");
			sound.Name = name;
			sound.SoundId = `rbxassetid://${id}`;
			sound.Parent = this.Handle;
			return sound;
		};

		this.Sounds = {
			Slash: createSound("SwordSlash", 12222216),
			Lunge: createSound("SwordLunge", 12222208),
			Unsheath: createSound("Unsheath", 12222225),
		};

		const createAnimation = (name: string, id: number): Animation => {
			const anim = new Instance("Animation");
			anim.Name = name;
			anim.AnimationId = `rbxassetid://${id}`;
			anim.Parent = this.tool;
			return anim;
		};

		this.R15SlashAnim = createAnimation("R15Slash", Animations.R15Slash);
		this.R15LungeAnim = createAnimation("R15Lunge", Animations.R15Lunge);
	}

	public Setup(): void {
		//Rescripted by Luckymaxer
		//EUROCOW WAS HERE BECAUSE I MADE THE PARTICLES AND THEREFORE THIS ENTIRE SWORD PRETTY AND LOOK PRETTY WORDS AND I'D LIKE TO DEDICATE THIS TO MY FRIENDS AND HI LUCKYMAXER PLS FIX SFOTH SWORDS TY LOVE Y'ALl
		//Updated for R15 avatars by StarWars
		//Re-updated by TakeoHonorable
		//[MODIFIED]

		this.tool.Grip = Grips.Up;
		this.tool.Enabled = true;

		const UntagHumanoid = (humanoid: Humanoid) => {
			for (const v of humanoid.GetChildren()) {
				if (v.IsA("ObjectValue") && v.Name === "creator") v.Destroy();
			}
		};

		const TagHumanoid = (humanoid: Humanoid, plr: Player) => {
			UntagHumanoid(humanoid);
			const Creator_Tag = new Instance("ObjectValue");
			Creator_Tag.Name = "creator";
			Creator_Tag.Value = plr;
			Debris.AddItem(Creator_Tag, 2);
			Creator_Tag.Parent = humanoid;
		};

		const CheckIfAlive = (): boolean => {
			const player = this.GetPlayerFromEquipped();
			if (!player) return false;

			return (
				player !== undefined &&
				player.Parent !== undefined &&
				this.Character !== undefined &&
				this.Character.Parent !== undefined &&
				this.Humanoid !== undefined &&
				this.Humanoid.Parent !== undefined &&
				this.Humanoid.Health > 0 &&
				this.Torso !== undefined &&
				this.Torso.Parent !== undefined
			);
		};

		const Blow = (Hit: BasePart) => {
			if (!Hit || !Hit.Parent || !CheckIfAlive() || !this.ToolEquipped) return;

			const Character = this.Character;
			if (!Character) return;

			const RightArm = Character.FindFirstChild("Right Arm") ?? Character.FindFirstChild("RightHand");
			if (!RightArm) return;

			const RightGrip = RightArm.FindFirstChild("RightGrip") as Weld;
			if (!RightGrip || (RightGrip.Part0 !== this.Handle && RightGrip.Part1 !== this.Handle)) return;

			const hitCharacter = Hit.Parent as Model;
			if (hitCharacter === Character) return;

			const humanoid = hitCharacter.FindFirstChildOfClass("Humanoid")!;
			if (!humanoid || humanoid.Health === 0) return;

			const hitPlayer = Players.GetPlayerFromCharacter(hitCharacter);
			const player = this.GetPlayerFromEquipped();
			if (hitPlayer && hitPlayer === player) return;

			TagHumanoid(humanoid, player!);
			humanoid.TakeDamage(this.Damage);
		};

		const Attack = () => {
			this.Damage = DamageValues.SlashDamage;
			this.Sounds.Slash.Play();

			const Humanoid = this.Humanoid;
			if (!Humanoid) return;

			if (Humanoid.RigType === Enum.HumanoidRigType.R6) {
				const Anim = new Instance("StringValue");
				Anim.Name = "toolanim";
				Anim.Value = "Slash";
				Anim.Parent = this.tool;
			} else if (Humanoid.RigType === Enum.HumanoidRigType.R15) {
				const Character = this.Character;
				if (!Character) return;
				const animator = Character.WaitForChild("Humanoid").WaitForChild("Animator") as Animator;
				const Track = animator.LoadAnimation(this.R15SlashAnim);
				Track.Play(0);
			}
		};

		const Lunge = () => {
			this.Damage = DamageValues.LungeDamage;
			this.Sounds.Lunge.Play();

			const Humanoid = this.Humanoid;
			if (!Humanoid) return;

			if (Humanoid.RigType === Enum.HumanoidRigType.R6) {
				const Anim = new Instance("StringValue");
				Anim.Name = "toolanim";
				Anim.Value = "Lunge";
				Anim.Parent = this.tool;
			} else if (Humanoid.RigType === Enum.HumanoidRigType.R15) {
				const Character = this.Character;
				if (!Character) return;
				const animator = Character.WaitForChild("Humanoid").WaitForChild("Animator") as Animator;
				const Track = animator.LoadAnimation(this.R15LungeAnim);
				Track.Play(0);
			}

			task.wait(0.2);
			this.tool.Grip = Grips.Out;
			task.wait(0.6);
			this.tool.Grip = Grips.Up;

			this.Damage = DamageValues.SlashDamage;
		};

		const Activated = () => {
			if (!this.tool.Enabled || !this.ToolEquipped || !CheckIfAlive()) return;

			this.tool.Enabled = false;
			const [Tick] = RunService.Stepped.Wait();

			if (Tick - this.LastAttack < 0.2) {
				Lunge();
			} else {
				Attack();
			}

			this.LastAttack = Tick;
			this.Damage = DamageValues.BaseDamage;
			this.tool.Enabled = true;
		};

		const Equipped = () => {
			const Character = this.tool.Parent as Model;
			this.Character = Character;
			if (!Character) return;

			const player = Players.GetPlayerFromCharacter(Character);
			this.Humanoid = Character.FindFirstChildOfClass("Humanoid") as Humanoid | undefined;
			this.Torso = (Character.FindFirstChild("Torso") ?? Character.FindFirstChild("HumanoidRootPart")) as
				| BasePart
				| undefined;

			if (!CheckIfAlive()) return;

			this.ToolEquipped = true;
			this.Sounds.Unsheath.Play();

			if (this.Connection) this.Connection.Disconnect();

			this.Connection = this.Handle.Touched.Connect(Blow);
		};

		const Unequipped = () => {
			this.tool.Grip = Grips.Up;
			this.ToolEquipped = false;
			if (this.Connection) {
				this.Connection.Disconnect();
				this.Connection = undefined;
			}
		};

		this.trove.add(this.tool.Activated.Connect(Activated));
		this.trove.add(this.tool.Equipped.Connect(Equipped));
		this.trove.add(this.tool.Unequipped.Connect(Unequipped));

		this.trove.add(() => {
			if (this.Connection) this.Connection.Disconnect();

			this.Connection = undefined;

			const Humanoid = this.Humanoid;
			if (Humanoid) UntagHumanoid(Humanoid);
		});
	}
}
