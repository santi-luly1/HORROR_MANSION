// --<<SERVER>>--
import { Players } from "@rbxts/services";
import { Trove } from "@rbxts/trove";
import { BehaviorModule } from "server/types/ItemService";

export default abstract class Default implements BehaviorModule {
	protected trove: Trove;
	protected tool: Tool;

	constructor(tool: Tool) {
		this.trove = new Trove();
		this.tool = tool;

		this.trove.add(tool); // link for cleanup
	}

	public abstract Setup(): void;
	public Destroy(): void {
		this.trove.clean();
	}
	public GetPlayerFromEquipped(): Player | undefined {
		// assumes that the tool is equipped, thus being inside the player's character.
		return Players.GetPlayerFromCharacter(this.tool.Parent);
	}
}
