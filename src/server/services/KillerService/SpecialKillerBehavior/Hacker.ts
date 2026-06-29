/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import { RunService } from "@rbxts/services";
import simplepath from "@rbxts/simplepath";
import Default from "./Default";
import Killer from "../Killer";

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

export default class Hacker extends Default {
	constructor(killer: Killer) {
		super(killer);
	}
	public Setup(): void {
		const killer = this.killer;
		killer.humanoid.WalkSpeed = 24;

		// Noclip
		killer.trove.add(
			RunService.Stepped.Connect(() => {
				for (const part of killer.model.GetDescendants()) {
					if (part.IsA("BasePart")) part.CanCollide = false;
				}
			}),
		);

		killer.PlaySound(123437024423007, { Looped: true, Volume: 0.5 }); // ambience

		// AI
		killer.trove.add(
			task.spawn(() => {
				while (this.killer.IsAlive()) {
					RunService.Heartbeat.Wait(); // sooo smooth
					const target = simplepath.GetNearestCharacter(this.killer.humanoidRootPart.Position);
					if (!target) {
						task.wait(0.5); // we wait so Roblox does not explode
						return;
					}

					this.killer.humanoid.MoveTo(target.GetPivot().Position); // this is a little bit of a bottleneck, if the player moves, the model wouldn't nice until it reaches the end.
					this.killer.humanoid.MoveToFinished.Wait();
				}
			}),
		);
	}

	public GetBonkSound(): number {
		return 99928861785298;
	}

	public GetKillSound(): number {
		return 4697392376;
	}

	public GetPerishSound(): number {
		return 135674621249840;
	}

	public GetBonkDelay(): number {
		return 1.5;
	}
}
