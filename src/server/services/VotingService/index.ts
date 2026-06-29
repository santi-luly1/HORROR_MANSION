/*
[=[
    @class VotingService
    @author santi-luly1
    @description Server-side map voting manager

    CHANGELOG: [
        03/01/26 --> Initial version.
		03/13/26 --> Ensured StartVoting promise resolves when voting ends early or cancels.
		05/13/26 --> Parsed into roblox-ts.
    ]
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
// Roblox services
import { Players, ServerStorage, Workspace } from "@rbxts/services";

// Packages
import { Service, OnInit, OnStart } from "@flamework/core";
import { Trove } from "@rbxts/trove";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";
import { t } from "@rbxts/t";

// Types
import RoundService from "server/services/RoundService";
import * as Types from "server/types/VotingService";

// Networking
import VotingServiceNetwork from "shared/networking/VotingServiceNetwork";

// const utilities
import SpecialMapBehavior from "./SpecialMapBehavior";

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export default class VotingServiceClass implements OnInit, OnStart {
	/*
		state
	*/
	private isVoting = false;
	private votes = new Map<number, string>();
	private mapOptions: Types.MapData[] = [];
	private winningMap = "N/A";

	/*
		runtime fields
	*/
	public VotingStarted = new Signal<(mapOptions: Types.MapData[]) => void>();
	public VotingEnded = new Signal<(winner: string, voteCount: Map<string, number>) => void>();
	public VoteCast = new Signal<(player: Player, mapName: string, previousVote: string) => void>();
	private declare countdownThread: thread;

	/*
	--------------------------------------------------------------------
	--- Constructor
	--------------------------------------------------------------------
	*/
	constructor(private readonly RoundService: RoundService) {}

	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/
	private MapsFolder = ServerStorage.WaitForChild("Maps");
	private readonly VOTING_DURATION = 10; // should be the round's intermission time, but if it'll be readonly, then it will have to be hardcodded.
	private readonly DEFAULT_VOTING_COUNT = 3; // ammount of maps that appear as options

	private voteCheck = t.strictArray(t.instanceOf("Player"), t.string);

	/*
	--------------------------------------------------------------------
	--- Helpers
	--------------------------------------------------------------------
	*/
	private getMapData(mapName: string): Types.MapData | undefined {
		const map = this.MapsFolder.FindFirstChild(mapName);
		if (!map) {
			return undefined;
		}

		const thumb = map.GetAttribute("thumbnail_id") as number | undefined;
		return {
			Name: map.Name,
			Thumbnail: `rbxassetid://${thumb ?? 13239978947}`,
		} as Types.MapData;
	}

	private getRandomMaps(count: number): string[] {
		const allMaps = this.MapsFolder.GetChildren();
		const selected: string[] = [];
		const used: boolean[] = [];

		if (allMaps.size() === 0) return selected;

		// clamp count to available maps (avoids crash)
		const maxCount = math.clamp(count, 1, allMaps.size());

		while (selected.size() < maxCount) {
			const index = math.random(0, allMaps.size() - 1);
			if (!used[index]) {
				used[index] = true;
				selected.push(allMaps[index].Name);
			}
		}

		return selected;
	}

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/

	public onInit() {
		// this.VOTING_DURATION = this.RoundService.GetIntermissionTimeout();

		SpecialMapBehavior.Init();

		VotingServiceNetwork.Server.Get("CastVote").Connect((player: Player, mapName: string) => {
			return this.CastVote(player, mapName);
		});

		VotingServiceNetwork.Server.Get("GetMapOptions").SetCallback(() => this.GetMapOptions());
	}

	public onStart() {
		math.randomseed(os.clock());

		this.RoundService.RoundEnded.Connect((skipped) => {
			if (skipped) return;

			this.StartVoting()
				.andThen((winningMap) => {
					// TODO: do not hard-code the map's name to "Map"
					const existing = Workspace.FindFirstChild("Map");
					if (existing && existing.IsA("Model")) existing.Destroy();

					const mapTemplate = this.MapsFolder.FindFirstChild(winningMap);
					if (!mapTemplate || !mapTemplate.IsA("Model")) {
						warn(`[${script.Name}] Winning map "${winningMap}" not found or not a Model.`);
						return;
					}

					const newMapClone = mapTemplate.Clone() as Model;
					const mapTrove = new Trove();
					newMapClone.Parent = Workspace;
					newMapClone.Name = "Map";

					mapTrove.attachToInstance(newMapClone);
					const behavior = SpecialMapBehavior.Get(winningMap);
					behavior.OnMapLoaded(newMapClone, mapTrove);

					for (const player of Players.GetPlayers()) {
						task.spawn(() => player.LoadCharacterAsync());
					}

					// TODO: add an intermission time between map changes, maybe 15s?

					// this.RoundService.Stop("**", true).catch(warn);
				})
				.catch(warn);
		});
	}

	/*
	--------------------------------------------------------------------
	--- Public API
	--------------------------------------------------------------------
	*/
	public async StartVoting(mapNames?: string[]): Promise<string> {
		return new Promise((resolve, reject, onCancel) => {
			if (this.isVoting) {
				return reject("Voting already in progress");
			}

			this.isVoting = true;
			this.votes.clear();
			this.winningMap = "N/A";

			const options = mapNames ?? this.getRandomMaps(this.DEFAULT_VOTING_COUNT);
			this.mapOptions = [];

			for (const name of options) {
				const data = this.getMapData(name);
				if (data) {
					this.mapOptions.push(data);
				}
			}

			if (this.mapOptions.size() === 0) {
				// just in case.
				this.isVoting = false;
				return reject("No valid maps to vote on");
			}

			VotingServiceNetwork.Server.Get("VotingStarted").SendToAllPlayers(this.mapOptions, this.VOTING_DURATION);
			this.VotingStarted.Fire(this.mapOptions);

			const startTime = tick();
			this.countdownThread = task.spawn(() => {
				while (this.isVoting && tick() - startTime < this.VOTING_DURATION) {
					task.wait(0.1);
				}

				if (this.isVoting) {
					const winner = this.EndVoting();
					return resolve(winner);
				}
			});

			onCancel(() => {
				this.isVoting = false;
				task.cancel(this.countdownThread);
				return reject("Voting cancelled");
			});
		}) as Promise<string>;
	}

	public EndVoting(): string {
		if (!this.isVoting) {
			return this.winningMap;
		}

		this.isVoting = false;

		const voteCounts = new Map<string, number>();
		for (const [, mapName] of pairs(this.votes)) {
			if (mapName === undefined) continue;
			voteCounts.set(mapName, (voteCounts.get(mapName) ?? 0) + 1);
		}

		let maxVotes = 0;
		let winner = this.mapOptions[0] ? this.mapOptions[0].Name : "N/A";
		const ties: string[] = [];

		for (const [mapName, votes] of pairs(voteCounts)) {
			if (votes > maxVotes) {
				maxVotes = votes;
				winner = mapName;
				ties.clear();
				ties.push(mapName);
			} else if (votes === maxVotes) {
				ties.push(mapName);
			}
		}

		if (ties.size() > 1) {
			const idx = math.random(0, ties.size() - 1);
			winner = ties[idx];
		}

		this.winningMap = winner;

		VotingServiceNetwork.Server.Get("VotingEnded").SendToAllPlayers(winner);
		this.VotingEnded.Fire(winner, voteCounts);

		return winner;
	}

	public CastVote(player: Player, mapName: string): boolean {
		if (!this.isVoting) {
			return false;
		}

		assert(this.voteCheck([player, mapName]));

		let validOption = false;
		for (const option of this.mapOptions) {
			if (option.Name === mapName) {
				validOption = true;
				break;
			}
		}

		if (!validOption) {
			return false;
		}

		const previousVote = this.votes.get(player.UserId) as string;
		this.votes.set(player.UserId, mapName);

		VotingServiceNetwork.Server.Get("VoteUpdated").SendToPlayer(player, mapName, this.GetVotes());
		this.VoteCast.Fire(player, mapName, previousVote);

		return true;
	}

	public GetMapOptions(): Types.MapData[] {
		return this.mapOptions;
	}

	public GetWinningMap(): string {
		return this.winningMap;
	}

	public IsVoting(): boolean {
		return this.isVoting;
	}

	public GetVotes(): Map<string, number> {
		const counts = new Map<string, number>();
		for (const [, mapName] of pairs(this.votes)) {
			if (mapName === undefined) continue;
			counts.set(mapName, (counts.get(mapName) ?? 0) + 1);
		}
		return counts;
	}
}
