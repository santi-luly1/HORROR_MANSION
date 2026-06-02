/*
[=[
	@class KillerService
    @author a
    @description Main API for killer(s) management
	@note as I added OOP killers, I also removed the second arguments from promises (spawnIndex), so I need to implement them into the Killer's class

    CHANGELOG: [
		26/01/10 --> Adapted from original source.
		26/01/11 --> Added module-wide typechecking and random spawn selector with its APIs.
		26/01/28 --> Added multiple killers support and signals.
		26/01/30 --> Added GetRandomSpawnIndex API, and added killer sounds.
		26/02/15 --> Added SpecialKillerBehavior support and removed sounds index.
		26/02/21 --> Fixed SpawnAll, it was failing for the slightest rejection.
		26/03/13 --> Added spawn lock to prevent concurrent duplicate killer spawns (AI).
		26/04/11 --> Re-organized the public API to make it more "human-readable" (was hurting my eyes and brain).
		26/04/17 --> Added GetKillerInRound API.
		26/04/25 --> Added a delay before deleting the killer's model, and made the module to be OOP instead (..too much?).
		26/05/06 --> Moved humanoid-related stuff into KillerClass to handle.
        26/05/24 --> Parsed into roblox-ts
    ]
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
// Roblox services
import { ServerStorage, Workspace } from "@rbxts/services";

// Packages
import { Service, OnInit, OnStart } from "@flamework/core";
import { Trove } from "@rbxts/trove";
import { t } from "@rbxts/t";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";

// Types
import * as Types from "server/types/KillerServiceTypes";

// Networking
import Networking from "shared/networking/KillerServiceNetwork";

// Local utilities
import SpecialKillerBehavior from "./SpecialKillerBehavior";
import Killer from "./Killer";

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export class KillerService implements OnInit, OnStart {
	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/
	private killers: Types.Killer[] = [];
	private spawningNames: Record<string, true | undefined> = {};

	public declare KillerSpawned: Signal<(killer: Types.Killer) => void>;
	public declare KillerCleared: Signal<(killerName: string) => void>;

	private declare trove: Trove;

	private KillersFolder = ServerStorage.WaitForChild("Killers") as Folder;
	private KillerTemplates = this.KillersFolder.GetChildren() as Model[];

	private NAMES: string[] = table.create(this.KillerTemplates.size() + 2, "*");
	private spawnCheck = t.strictArray(t.string, t.number);

	/*
	--------------------------------------------------------------------
	--- Constructor
	--------------------------------------------------------------------
	*/
	public constructor() {}

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public onInit() {}

	public onStart() {
		this.trove = new Trove();
		this.KillerSpawned = new Signal();
		this.KillerCleared = new Signal();
		this.NAMES[2] = "**";
		for (let i = 0; i < this.KillerTemplates.size(); i++) {
			this.NAMES[i + 2] = this.KillerTemplates[i].Name;
		}
		SpecialKillerBehavior.Init();

		Networking.Server.Get("GetKillersName").SetCallback(() => {
			return [this.GetKillersName()];
		});
		math.randomseed(os.clock());
	}

	/*
	--------------------------------------------------------------------
	--- Helpers
	--------------------------------------------------------------------
	*/
	private getSpawnCFrame(index: number): CFrame {
		const spawns = Workspace.FindFirstChild("Map")!.FindFirstChild("spawns")!.GetChildren() as SpawnLocation[];
		return spawns[index].CFrame.mul(new CFrame(0, 10, 0));
	}

	/*
	--------------------------------------------------------------------
	--- Private Methods
	--------------------------------------------------------------------
	*/
	private async spawn(name: string, spawnIndex: number): Promise<Types.Killer> {
		return new Promise((resolve, reject, onCancel) => {
			if (!this.spawnCheck([name, spawnIndex])) {
				return reject(`[${script.Name}] bad argument(s)`);
			}

			if (!this.IsValidName(name)) {
				return reject(`Name '${name}' is invalid`);
			}

			if (this.spawningNames[name]) {
				return reject(`Killer '${name}' spawn already in progress`);
			}
			this.spawningNames[name] = true;

			const releaseSpawnLock = () => {
				this.spawningNames[name] = undefined;
			};

			spawnIndex = spawnIndex > 0 ? spawnIndex : this.GetRandomSpawnIndex();

			const trove = new Trove();

			if (
				onCancel(() => {
					releaseSpawnLock();
					trove.clean();
				})
			) {
				return;
			}

			const template = this.KillersFolder.FindFirstChild(name) as Model | undefined;
			if (!template) {
				releaseSpawnLock();
				return reject("Killer not found");
			}

			const clone = template.Clone();
			clone.Parent = Workspace;

			const behaviorFactory = SpecialKillerBehavior.Get(name);
			const killer = new Killer(clone, trove);
			killer.id = this.killers.size() + 1;
			killer.behavior = new behaviorFactory(killer);

			this.killers.push(killer);

			killer.TeleportTo(this.getSpawnCFrame(spawnIndex));

			killer.behavior.Setup();

			trove.add(() => {
				const idx = this.killers.indexOf(killer);
				if (idx !== -1) {
					this.killers.remove(idx);
					this.KillerCleared.Fire(killer.name);
				}
			});

			this.trove.add(trove);
			this.KillerSpawned.Fire(killer);
			releaseSpawnLock();
			return resolve(killer);
		});
	}

	/*
	--------------------------------------------------------------------
	--- Public API
	--------------------------------------------------------------------
	*/
	public GetRandomSpawnIndex(): number {
		const spawns = Workspace.FindFirstChild("Map")!.FindFirstChild("spawns")!.GetChildren() as BasePart[];
		return math.random(1, spawns.size());
	}

	public GetKillersName(includeSpecial?: boolean): string[] {
		if (includeSpecial) return this.NAMES;
		return this.NAMES.filter((v) => {
			return this.IsValidName(v, false);
		});
	}

	public GetKillerInRound(name: string): Types.Killer[] {
		const killers: Types.Killer[] = [];
		for (const k of this.killers) {
			if (k.name === name) {
				killers.push(k);
			}
		}
		return killers;
	}

	public IsValidName(name: string, includeSpecial?: boolean): boolean {
		if (includeSpecial) {
			return (
				this.NAMES.find((value) => {
					return value === name;
				}) !== undefined
			);
		}
		return (
			this.NAMES.find((value) => {
				return value === name;
			}) !== undefined &&
			name !== "*" &&
			name !== "**"
		);
	}

	public GetCurrentKillers(): Types.Killer[] {
		return this.killers;
	}

	public Clear() {
		this.trove.clean();
		table.clear(this.killers);
	}

	public async SpawnKiller(name: string, spawnIndex: number): Promise<Types.Killer> {
		if (name === "*") {
			error("Bulk spawn not allowed from this API.");
		} else if (name === "**") {
			const pick = this.KillerTemplates[math.random(0, this.KillerTemplates.size() - 1)];
			return this.spawn(pick.Name, spawnIndex);
		} else {
			return this.spawn(name, spawnIndex);
		}
	}

	public async SpawnKillers(names: string[], spawnIndex: number): Promise<Types.Killer[]> {
		const valid = names.filter((n) => this.IsValidName(n));
		print(valid, names);
		if (valid.size() === 0) return Promise.reject("No valid killers to spawn") as Promise<Types.Killer[]>; // ugly

		const killers: Types.Killer[] = [];
		const errors: string[] = [];

		// chain sequentially
		let chain = Promise.resolve();
		for (const name of valid) {
			chain = chain
				.andThen(() => this.SpawnKiller(name, spawnIndex))
				.andThen((k) => {
					killers.push(k);
				})
				.catch((e) => {
					errors.push(tostring(e));
				});
		}

		return chain.andThen(() => {
			if (killers.size() > 0) return killers;
			return Promise.reject(`All ${errors.size()} killer spawns failed: ${errors.join(", ")}`);
		}) as Promise<Types.Killer[]>;
	}

	public async SpawnAll(spawnIndex: number): Promise<Types.Killer[]> {
		const validNames: string[] = [];

		for (const name of this.GetKillersName()) {
			if (this.IsValidName(name)) {
				validNames.push(name);
			}
		}

		if (validNames.size() === 0) {
			return Promise.reject("No valid killers available to spawn") as Promise<Types.Killer[]>; // ugly
		}

		return this.SpawnKillers(validNames, spawnIndex);
	}
}
