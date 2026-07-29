/*
[=[
	@class PlayerDeathHandler
    @author santi-luly1
    @description Server death manager for players
	@note Maybe I could give this module some use, like being the one handling the player's death instead of just "Humanoid.Health = 0" on modules.

    CHANGELOG: [
		25/12/31 --> Adapted from original source.
		26/01/30 --> Indexed all the deaths sounds into a module.
        26/07/16 --> Parsed into roblox-ts.
	]
]=]
*/

import { Service, OnInit, OnStart } from "@flamework/core";
import SoundsIndex from "./sounds";

const Players = game.GetService("Players");

@Service()
export default class PlayerDeathHandlerClass implements OnInit, OnStart {
	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/

	public onInit() {}

	public onStart() {
		math.randomseed(tick()); // just bc

		Players.PlayerAdded.Connect((player) => {
			player.CharacterAdded.Connect((character: Model) => {
				// player.SetAttribute("Dead", false) // little bug (race conditions)
				const hum = character.WaitForChild("Humanoid", 30) as Humanoid; // will this yield for the entire server? Hmmm
				if (hum) {
					hum.Died.Once(() => {
						// warn(`[{script.Name}] Player {player.Name} has died.`)
						player.SetAttribute("Dead", true);

						// generic sound
						const idx = math.random(1, SoundsIndex.size());
						const track = new Instance("Sound");
						track.SoundId = `rbxassetid://${SoundsIndex[idx]}`;
						track.Parent = character.PrimaryPart!;
						track.Ended.Once(() => {
							track.Destroy(); // would this even be needed? Character is gonna respawn, deleting this in the process anyways
						});
						track.Play();
					});
				}
			});
		});
	}
}
