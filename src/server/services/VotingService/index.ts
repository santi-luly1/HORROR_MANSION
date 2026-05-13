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
import { Trove } from "@rbxts/trove";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";
import { t } from "@rbxts/t";

// Types
import { RoundServiceTypes } from "server/types/RoundServiceTypes";
import * as Types from "server/types/VotingService";

// Networking
import VotingServiceNetwork from "shared/networking/VotingServiceNetwork";

// const utilities
import SpecialMapBehavior from "./SpecialMapBehavior";

// Services
let RoundService: RoundServiceTypes;

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/
class VotingServiceClass implements Types.VotingServiceTypes {
	/*
		state
	*/
	public _init = false;
	public _start = false;
	private _isVoting = false;
	private _votes: Record<number, string> = {};
	private _mapOptions: Types.MapData[] = [];
	private _winningMap = "N/A";

	/*
		runtime fields
	*/
	private _trove: Trove = new Trove();
	public VotingStarted: Signal = new Signal();
	public VotingEnded: Signal = new Signal();
	public VoteCast: Signal = new Signal();
	private _voteResolve: (winner: string) => void = (winner) => {};
	private _countdownThread?: thread;

	// dependencies
	public static Dependencies = ["RoundService"];

	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/
	private MapsFolder = ServerStorage.WaitForChild("Maps");
	private VOTING_DURATION = 0;

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

		// clamp count to available maps
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
	public Init(registry: { RoundService: RoundServiceTypes }) {
		//TODO: definetly this is not the whole registry.
		assert(!this._init, `[${script.Name}] - Module already initialized.`);
		this._init = true;

		RoundService = registry.RoundService;
		this.VOTING_DURATION = RoundService.GetIntermissionTimeout();

		this.VotingStarted = new Signal();
		this.VotingEnded = new Signal();
		this.VoteCast = new Signal();

		SpecialMapBehavior.Init();

		VotingServiceNetwork.Server.Get("CastVote").Connect((player: Player, mapName: string) => {
			return this.CastVote(player, mapName);
		});

		VotingServiceNetwork.Server.Get("GetMapOptions").SetCallback(() => this.GetMapOptions());
	}

	public Start() {
		assert(this._init, `[${script.Name}] - Module not initialized.`);
		assert(!this._start, `[${script.Name}] - Module already started.`);
		this._start = true;

		math.randomseed(os.clock());

		this._trove.add(
			RoundService.RoundEnded.Connect((skipped: boolean) => {
				if (skipped) {
					return;
				}

				this.StartVoting()
					.andThen((winningMap) => {
						// TODO: do not hard-code the map's name to "Map"
						const existing = Workspace.FindFirstChild("Map");
						if (existing && existing.IsA("Model")) existing.Destroy();

						const mapTemplate = this.MapsFolder.FindFirstChild(winningMap);
						if (!mapTemplate || !mapTemplate.IsA("Model")) {
							warn(`[VotingService] Winning map "${winningMap}" not found or not a Model.`);
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

						RoundService.Stop("**", true).catch(warn);
					})
					.catch(warn);
			}),
		);
	}

	/*
--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------
*/
	public StartVoting(mapNames?: string[]): Promise<string> {
		return new Promise((resolve, reject, onCancel) => {
			if (this._isVoting) {
				return reject("Voting already in progress");
			}

			this._isVoting = true;
			let resolved = false;
			const finalize = (winner: string) => {
				if (resolved) {
					return;
				}
				resolved = true;
				//this._voteResolve = undefined;
				return resolve(winner);
			};
			this._voteResolve = finalize;
			this._votes = {};
			this._winningMap = "N/A";

			const options = mapNames ?? this.getRandomMaps(3);
			this._mapOptions = [];

			for (const name of options) {
				const data = this.getMapData(name);
				if (data) {
					this._mapOptions.push(data);
				}
			}

			if (this._mapOptions.size() === 0) {
				// just in case.
				this._isVoting = false;
				//this._voteResolve = undefined;
				return reject("No valid maps to vote on");
			}

			VotingServiceNetwork.Server.Get("VotingStarted").SendToAllPlayers(this._mapOptions, this.VOTING_DURATION);
			this.VotingStarted.Fire(this._mapOptions);

			const startTime = tick();
			this._countdownThread = task.spawn(() => {
				while (this._isVoting && tick() - startTime < this.VOTING_DURATION) {
					task.wait(0.1);
				}

				if (this._isVoting) {
					const winner = this.EndVoting();
					return finalize(winner);
				}
			});

			onCancel(() => {
				this._isVoting = false;
				if (this._countdownThread) {
					task.cancel(this._countdownThread);
				}
				//this._voteResolve = undefined;
				return reject("Voting cancelled");
			});
		}) as Promise<string>;
	}

	public EndVoting(): string {
		if (!this._isVoting) {
			return this._winningMap;
		}

		this._isVoting = false;

		const voteCounts: Record<string, number> = {};
		for (const [, mapName] of pairs(this._votes)) {
			if (mapName === undefined) continue;
			voteCounts[mapName] = (voteCounts[mapName] ?? 0) + 1;
		}

		let maxVotes = 0;
		let winner = this._mapOptions[0] ? this._mapOptions[0].Name : "N/A";
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

		this._winningMap = winner;

		VotingServiceNetwork.Server.Get("VotingEnded").SendToAllPlayers(winner);
		this.VotingEnded!.Fire(winner, voteCounts);

		if (this._voteResolve) {
			this._voteResolve(winner);
		}

		return winner;
	}

	public CastVote(player: Player, mapName: string): boolean {
		if (!this._isVoting) {
			return false;
		}

		this.voteCheck([player, mapName]);

		let validOption = false;
		for (const option of this._mapOptions) {
			if (option.Name === mapName) {
				validOption = true;
				break;
			}
		}

		if (!validOption) {
			return false;
		}

		const previousVote = this._votes[player.UserId];
		this._votes[player.UserId] = mapName;

		VotingServiceNetwork.Server.Get("VoteUpdated").SendToPlayer(player, mapName, this.GetVotes());
		this.VoteCast.Fire(player, mapName, previousVote);

		return true;
	}

	public GetMapOptions(): Types.MapData[] {
		return this._mapOptions;
	}

	public GetWinningMap(): string {
		return this._winningMap;
	}

	public IsVoting(): boolean {
		return this._isVoting;
	}

	public GetVotes(): Record<string, number> {
		const counts: Record<string, number> = {};
		for (const [, mapName] of pairs(this._votes)) {
			if (mapName === undefined) continue;
			counts[mapName] = (counts[mapName] ?? 0) + 1;
		}
		return counts;
	}
}

/*
--------------------------------------------------------------------
--- Export
--------------------------------------------------------------------
*/
const VotingService = new VotingServiceClass();
export = VotingService;
