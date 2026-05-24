/*
[=[
	@class KillerService
    @author santi-luly1
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

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export class KillerService implements Types.default, OnInit, OnStart {
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
	constructor() {
		this.NAMES[2] = "**";
		for (let i = 0; i < this.KillerTemplates.size(); i++) {
			this.NAMES[i + 2] = this.KillerTemplates[i].Name;
		}
	}

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public onInit() {
		this.trove = new Trove();
		this.KillerSpawned = new Signal();
		this.KillerCleared = new Signal();
		SpecialKillerBehavior.Init();

		Networking.Server.Get("GetKillersName").SetCallback(() => {
			return [this.GetKillersName()];
		});
	}

	public onStart() {
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
	private _spawn(name: string, spawnIndex: number): Promise<Types.Killer> {
		return new Promise((resolve, reject, onCancel) => {
			if (!this.spawnCheck([name, spawnIndex])) {
				return reject(`[{script.Name}] bad argument(s)`);
			}

			if (!this.IsValidName(name)) {
				return reject(`Name '{name}' is invalid`);
			}

			if (this.spawningNames[name]) {
				return reject(`Killer '{name}' spawn already in progress`);
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
				if (idx) {
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

	public GetKillersName(): string[] {
		return this.NAMES;
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
			return this.NAMES.find(name) !== undefined;
		}
		return table.find(this.NAMES, name) !== undefined && name !== "*" && name !== "**";
	}

	public GetCurrentKillers(): Types.Killer[] {
		return this.killers;
	}

	public Clear() {
		this.trove.clean();
		table.clear(this.killers);
	}

	public SpawnKiller(name: string, spawnIndex: number): Promise<Types.Killer> {
		if (name === "*") {
			error("Bulk spawn not allowed from this API.");
		} else if (name === "**") {
			const pick = this.KillerTemplates[math.random(0, this.KillerTemplates.size() - 1)];
			return this._spawn(pick.Name, spawnIndex);
		} else {
			return this._spawn(name, spawnIndex);
		}
	}

	public SpawnKillers(names: string[], spawnIndex: number): Promise<Types.Killer[]> {
		const promises: Promise<{ ok: boolean; result: unknown }>[] = [];

		for (const name of names) {
			if (this.IsValidName(name)) {
				const p = this.SpawnKiller(name, spawnIndex)
					.andThen((model) => {
						return { ok: true, result: model };
					})
					.catch((err) => {
						return { ok: false, result: tostring(err) };
					});
				promises.push(p);
			}
		}

		if (promises.size() === 0) {
			return Promise.reject("No valid killers to spawn");
		}

		return Promise.all(promises).andThen((results) => {
			const killers: Types.Killer[] = [];
			const errors: string[] = [];

			for (const r of results) {
				if ((r as any).ok) {
					killers.push((r as any).result as Types.Killer);
				} else {
					errors.push((r as any).result as string);
				}
			}

			if (killers.size() > 0) {
				return killers;
			} else {
				return Promise.reject(`All ${errors.size()} killer spawns failed: ${errors.join(", ")}`);
			}
		});
	}

	public SpawnAll(spawnIndex: number): Promise<Types.Killer[]> {
		const validNames: string[] = [];

		for (const name of this.GetKillersName()) {
			if (this.IsValidName(name)) {
				validNames.push(name);
			}
		}

		if (validNames.size() === 0) {
			return Promise.reject("No valid killers available to spawn");
		}

		return this.SpawnKillers(validNames, spawnIndex);
	}
}
