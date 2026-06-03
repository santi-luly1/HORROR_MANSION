/*
[=[
	@class Killer
    @author santi-luly1
    @description Main API for killer object

    CHANGELOG: [
		26/04/25 --> Added this module.
		26/05/06 --> Added setupDefaultBehavior to setup basic properties and signals for each killer.
        26/05/24 --> Parsed into roblox-ts.
	]
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import { Trove } from "@rbxts/trove";
import type * as Types from "server/types/KillerService";
import SpecialKillerBehavior from "./SpecialKillerBehavior";

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

export default class Killer implements Types.Killer {
	public declare id: number; // KillerService.ts handles this.
	public name: string;
	public model: Model;
	public humanoid: Humanoid;
	public humanoidRootPart: BasePart;
	public hitbox: BasePart;
	public alive: boolean;
	public maxHealth: number;
	public health: number;
	public lastDamageTime: number;
	public behavior: Types.BehaviorModule;
	public trove: Trove;
	public state: Enum.HumanoidStateType;

	// runtime
	private anims: Map<number, Animation> = new Map();
	private animator: Animator;

	/*
	--------------------------------------------------------------------
	--- Constructor
	--------------------------------------------------------------------
	*/
	constructor(model: Model) {
		const behavior = SpecialKillerBehavior.Get(model.Name);

		this.name = model.Name;
		this.model = model;
		this.humanoid = model.FindFirstChildOfClass("Humanoid") as Humanoid;
		this.humanoidRootPart = model.FindFirstChild("HumanoidRootPart") as BasePart;
		this.hitbox = model.FindFirstChild("hitbox") as BasePart;
		this.alive = true;
		this.maxHealth = this.humanoid.MaxHealth;
		this.health = this.maxHealth;
		this.lastDamageTime = 0;
		this.behavior = new behavior(this); // is it allowed?
		this.trove = new Trove();
		this.state = Enum.HumanoidStateType.PlatformStanding; // should it be none?

		this.animator = new Instance("Animator") as Animator;
		this.animator.Parent = this.humanoid;

		this.trove.attachToInstance(model);

		this.setupStandardBehavior();
	}

	/*
	--------------------------------------------------------------------
	--- Helpers / Behavior
	--------------------------------------------------------------------
	*/
	private setupStandardBehavior() {
		const hum = this.humanoid;

		// humanoid defaults
		hum.WalkSpeed = 16;
		hum.UseJumpPower = true;
		hum.AutoJumpEnabled = true;
		hum.JumpPower = 50;

		// model setup
		this.model.SetAttribute("killer", true);

		// subscribers
		hum.Died.Once(() => {
			this.Kill();
		});

		const healthConn = hum.HealthChanged.Connect((health) => {
			this.health = health;
			this.behavior.OnHarm();
		});
		this.trove.add(healthConn);

		const sitConn = hum.GetPropertyChangedSignal("Sit").Connect(() => {
			if (!hum.Sit) return;
			task.delay(5, () => {
				this.humanoid.Jump = true;
			});
		});
		this.trove.add(sitConn);

		let canHit = true;

		const touchConn = this.hitbox.Touched.Connect((hit) => {
			const char = hit.Parent;
			const targetHum = char && char.FindFirstChildOfClass("Humanoid");

			if (
				canHit &&
				char &&
				targetHum &&
				targetHum.Health > 0 &&
				!char.FindFirstChildOfClass("ForceField") &&
				char.GetAttribute("killer") !== true
			) {
				canHit = false;

				this.PlaySound(this.behavior.GetBonkSound(), { Volume: 0.5 });

				this.behavior.DamageVictim(targetHum);

				task.delay(this.behavior.GetBonkDelay(), () => {
					canHit = true;
				});
			}
		});
		this.trove.add(touchConn);

		this.trove.add(() => {
			this.Kill();
		});

		this.hitbox.Transparency = 0.95;
	}

	/*
	--------------------------------------------------------------------
	--- Public API
	--------------------------------------------------------------------
	*/
	public IsAlive(): boolean {
		return this.alive;
	}

	public Damage(amount: number): boolean {
		if (!this.alive) return false;

		this.lastDamageTime = os.clock();
		this.health = math.clamp(this.health - amount, 0, this.maxHealth);
		this.humanoid.Health = this.health;

		this.PlaySound(this.behavior.GetBonkSound(), { Volume: 0.5 });

		if (this.health <= 0) this.Kill();

		return true;
	}

	public SetState(state: Enum.HumanoidStateType): void {
		this.state = state;
	}

	public Kill(): void {
		if (!this.alive) return;
		this.alive = false;

		this.humanoid.Health = 0;

		this.PlaySound(this.behavior.GetPerishSound(), { Volume: 1.0 });

		this.trove.clean();

		task.delay(10, () => {
			if (this.model && this.model.Parent) {
				this.model.Destroy();
			}
		});
	}

	public TeleportTo(cframe: CFrame): void {
		this.humanoidRootPart.CFrame = cframe;
	}

	public PlaySound(soundId: number, props?: { Volume?: number; Looped?: boolean }): Sound {
		const track = new Instance("Sound");
		track.Parent = this.humanoidRootPart;
		track.SoundId = `rbxassetid://${soundId}`;

		if (props) {
			track.Volume = props.Volume ?? 1;
			track.Looped = props.Looped ?? false;
		}

		const endedConn = track.Ended.Connect(() => {
			endedConn.Disconnect();
			track.Destroy();
		});
		// wait for load
		task.spawn(() => {
			do {
				task.wait();
			} while (!track.IsLoaded);
			track.Play();
		});
		return track;
	}

	public PlayAnimation(id: number): AnimationTrack {
		if (!this.anims.has(id)) {
			const anim = new Instance("Animation");
			anim.AnimationId = `rbxassetid://${id}`;
			this.anims.set(id, anim);
		}

		const animInstance = this.anims.get(id) as Animation;
		const animTrack = this.animator.LoadAnimation(animInstance);
		animTrack.Play();
		this.trove.add(() => {
			if (animTrack.IsPlaying) {
				animTrack.Stop();
			}
		});
		return animTrack;
	}

	// alias
	public Destroy() {
		return this.Kill();
	}
}
