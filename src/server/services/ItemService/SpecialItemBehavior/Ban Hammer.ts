// --<<SERVER>>--
import { Debris, Workspace } from "@rbxts/services";
import Default from "./Default";

export default class BanHammer extends Default {
	private Debounce = false;
	private CanDamage = false;

	private declare Character: Model;
	private CharacterSwingTrack: AnimationTrack | undefined;

	private SwingAnimation = new Instance("Animation");
	private declare SwingSound: Sound;
	private declare BanSound: Sound;

	public Setup(): void {
		// [Programmed by abrah_m]
		// [MODIFIED]

		this.SwingAnimation.AnimationId = "rbxassetid://32659706";

		const createSound = (name: string, soundId: string): Sound => {
			const sound = new Instance("Sound");
			sound.Name = name;
			sound.SoundId = soundId;
			sound.Parent = this.tool;
			return sound;
		};

		this.SwingSound = createSound("Swing", "rbxassetid://536642316");
		this.BanSound = createSound("Ban", "rbxassetid://147722910");

		const player = this.GetPlayerFromEquipped();
		if (!player) return;

		this.Character = (player.Character ?? player.CharacterAdded.Wait()) as Model;

		this.trove.add(
			this.tool.Equipped.Connect(() => {
				this.Character = (player.Character ?? player.CharacterAdded.Wait()) as Model;

				const animator = (this.Character.WaitForChild("Humanoid") as Humanoid).WaitForChild(
					"Animator",
				) as Animator;

				this.CharacterSwingTrack = animator.LoadAnimation(this.SwingAnimation);
			}),
		);

		this.trove.add(
			this.tool.Unequipped.Connect(() => {
				if (this.CharacterSwingTrack) {
					this.CharacterSwingTrack.Stop();
				}
			}),
		);

		this.trove.add(
			this.tool.Activated.Connect(() => {
				if (this.Debounce) {
					return;
				}

				this.Debounce = true;
				this.CanDamage = true;

				if (this.CharacterSwingTrack) {
					this.CharacterSwingTrack.Play();
				}

				this.SwingSound.Play();

				const handle = this.tool.FindFirstChild("Handle") as MeshPart | undefined;
				if (!handle) {
					this.Debounce = false;
					return;
				}

				let touchConnection: RBXScriptConnection | undefined;

				touchConnection = handle.Touched.Connect((hit) => {
					if (!this.CanDamage) {
						return;
					}

					const targetChar = hit.Parent as Instance | undefined;
					if (!targetChar) return;

					const humanoid = targetChar.FindFirstChildOfClass("Humanoid") as Humanoid | undefined;
					const hrp = targetChar.FindFirstChild("HumanoidRootPart") as Part | undefined;

					if (!humanoid || !hrp) {
						return;
					}
					if (humanoid.Health <= 0) {
						return;
					}

					if (targetChar === this.Character) {
						return;
					}

					this.CanDamage = false;

					this.BanSound.Play();

					const Explosion = new Instance("Explosion");
					Explosion.BlastRadius = 10;
					Explosion.BlastPressure = 0;
					Explosion.Position = hrp.Position;
					Explosion.Parent = Workspace;

					humanoid.Health = 0;

					for (const obj of targetChar.GetDescendants()) {
						if (obj.IsA("Motor6D") && (obj.Parent as Instance).Name !== "HumanoidRootPart") {
							const part0 = (obj as Motor6D).Part0;
							const part1 = (obj as Motor6D).Part1;

							if (part0 && part1) {
								const Socket = new Instance("BallSocketConstraint");
								const a1 = new Instance("Attachment");
								const a2 = new Instance("Attachment");

								a1.Parent = part0;
								a2.Parent = part1;
								Socket.Parent = part1;

								Socket.Attachment0 = a1;
								Socket.Attachment1 = a2;

								a1.CFrame = (obj as Motor6D).C0;
								a2.CFrame = (obj as Motor6D).C1;

								Socket.LimitsEnabled = true;
								Socket.TwistLimitsEnabled = true;

								(obj as Motor6D).Destroy();
							}
						}
					}

					const BodyVelocity = new Instance("BodyVelocity");
					BodyVelocity.MaxForce = new Vector3(1, 1, 1).mul(10000000);
					BodyVelocity.Velocity = (
						this.Character.FindFirstChild("HumanoidRootPart") as Part
					).CFrame.LookVector.mul(1000);
					BodyVelocity.Parent = hrp;

					Debris.AddItem(BodyVelocity, 0.1);
				});

				if (this.CharacterSwingTrack) {
					this.CharacterSwingTrack.Stopped.Wait();
				} else {
					task.wait(0.5); // fallback
				}

				touchConnection?.Disconnect();

				this.CanDamage = false;
				task.wait(0.1);
				this.Debounce = false;
			}),
		);
	}
}
