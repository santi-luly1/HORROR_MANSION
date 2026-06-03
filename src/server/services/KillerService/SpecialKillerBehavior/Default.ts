/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import { RunService } from "@rbxts/services";
import { BehaviorModule, Killer } from "server/types/KillerService";
import compute from "../Compute"; // make it not so hardcodded

/*
--------------------------------------------------------------------
--- Default (base) behavior
--------------------------------------------------------------------
*/
export class Default implements BehaviorModule {
	protected killer: Killer;

	constructor(killer: Killer) {
		this.killer = killer;
	}

	public Setup(): void {
		// AI fallback loop
		this.killer.trove.add(
			task.spawn(() => {
				while (this.killer.IsAlive()) {
					const ok = compute(this.killer.model, this.killer.trove);

					if (ok) RunService.Heartbeat.Wait(); // sooo smooth
					else task.wait(0.5);
				}
			}),
		);
	}

	public OnPlayerKill(victim: Model): void {
		this.killer.PlaySound(this.GetKillSound());
		warn(`${this.killer.model.Name} says L to ${victim.Name}`);
	}

	public DamageVictim(humanoid: Humanoid): void {
		humanoid.TakeDamage(20);
		if (humanoid.Health <= 0) this.OnPlayerKill(humanoid.Parent as Model);
	}

	public OnHarm(): void {
		// print("ouch!")
	}

	public GetBonkSound(): number {
		return 140110603417819;
	}

	public GetKillSound(): number {
		return 139771888058836;
	}

	public GetPerishSound(): number {
		return 135674621249840;
	}

	public GetBonkDelay(): number {
		return 1.5;
	}
}

export default Default;
