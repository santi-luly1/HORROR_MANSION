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
        26/05/24 --> Parsed into roblox-ts.
		26/07/16 --> Implemented logger.
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
import { debug, info, warn } from "@rbxts/logger";
import { t } from "@rbxts/t";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";

// Types
import * as Types from "server/types/KillerService";

// Networking
import Networking from "shared/networking/KillerServiceNetwork";

// Local utilities
import Killer from "./Killer";

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export default class KillerService implements OnInit, OnStart {
	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/
	private killers: Types.Killer[] = [];
	private spawningNames = new Set<string>();

	public KillerSpawned = new Signal<(killer: Types.Killer) => void>();
	public KillerCleared = new Signal<(killerName: string) => void>();

	private trove = new Trove();

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
		this.NAMES[2] = "**";
		for (let i = 0; i < this.KillerTemplates.size(); i++) {
			this.NAMES[i + 2] = this.KillerTemplates[i].Name;
		}

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
		const spawns = Workspace.FindFirstChild("Map")!.FindFirstChild("spawns")! as Folder;
		const spawn = spawns.FindFirstChild(tostring(index)) as SpawnLocation;
		return spawn.CFrame.mul(new CFrame(0, 10, 0));
	}

	/*
	--------------------------------------------------------------------
	--- Private Methods
	--------------------------------------------------------------------
	*/
	private spawn(name: string, spawnIndex: number): Promise<Types.Killer> {
		return new Promise((resolve, reject, onCancel) => {
			debug(`[${script.Name}] spawn() requested: name=${name}, spawnIndex=${spawnIndex}`);

			if (!this.spawnCheck([name, spawnIndex])) {
				warn(`[${script.Name}] spawn() rejected: bad argument(s)`);
				return reject(`[${script.Name}] bad argument(s)`);
			}
			if (!this.IsValidName(name)) {
				warn(`[${script.Name}] spawn() rejected: invalid name "${name}"`);
				return reject(`Name '${name}' is invalid`);
			}
			if (this.spawningNames.has(name)) {
				warn(`[${script.Name}] spawn() rejected: killer '${name}' already in progress`);
				return reject(`Killer '${name}' spawn already in progress`);
			}

			this.spawningNames.add(name);

			const releaseSpawnLock = () => this.spawningNames.delete(name);
			spawnIndex = spawnIndex > 0 ? spawnIndex : this.GetRandomSpawnIndex();

			const killerTrove = new Trove();

			if (
				onCancel(() => {
					releaseSpawnLock();
					killerTrove.clean();
					info(`[${script.Name}] spawn() cancelled: name=${name}, spawnIndex=${spawnIndex}`);
				})
			)
				return;

			const template = this.KillersFolder.FindFirstChild(name) as Model | undefined;
			if (!template) {
				releaseSpawnLock();
				warn(`[${script.Name}] spawn() failed: template not found for "${name}"`);
				return reject("Killer not found");
			}

			const clone = template.Clone();
			clone.Parent = Workspace;

			const killer = new Killer(clone);
			killer.id = this.killers.size() + 1;
			killerTrove.add(killer.trove); // add the killer's trove to it's "parent" trove
			killerTrove.attachToInstance(clone); // the killer's trove is also attached to the same instance, if killer dies, both troves dies.

			this.killers.push(killer);

			killer.TeleportTo(this.getSpawnCFrame(spawnIndex));

			killer.behavior.Setup();

			killerTrove.add(() => {
				const idx = this.killers.indexOf(killer);
				if (idx !== -1) {
					this.killers.remove(idx);
					this.KillerCleared.Fire(killer.name);
					debug(`[${script.Name}] killer cleared: ${killer.name} (id=${killer.id})`);
				}
			});

			this.trove.add(killerTrove);
			this.KillerSpawned.Fire(killer);

			info(`[${script.Name}] killer spawned: ${killer.name} (id=${killer.id}, spawnIndex=${spawnIndex})`);

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
		const idx = math.random(1, spawns.size());
		debug(`[${script.Name}] GetRandomSpawnIndex -> ${idx}`);
		return idx;
	}

	public GetKillersName(includeSpecial?: boolean): string[] {
		if (includeSpecial) return this.NAMES;
		return this.NAMES.filter((v) => this.IsValidName(v, false)); // isn't this redundant
	}

	public GetKillerInRound(name: string): Types.Killer[] {
		const killers: Types.Killer[] = [];
		for (const k of this.killers) {
			if (k.name === name) killers.push(k);
		}
		debug(`[${script.Name}] GetKillerInRound: ${name} -> ${killers.size()} killer(s)`);
		return killers;
	}

	public IsValidName(name: string, includeSpecial?: boolean): boolean {
		if (includeSpecial)
			return (
				this.NAMES.find((value) => {
					return value === name;
				}) !== undefined
			);

		return this.NAMES.find((value) => value === name) !== undefined && name !== "*" && name !== "**";
	}

	public GetCurrentKillers(): Types.Killer[] {
		return this.killers;
	}

	public Clear() {
		info(`[${script.Name}] Clear() called. Current killers: ${this.killers.size()}`);
		this.trove.clean();
		this.killers.clear();
	}

	public async SpawnKiller(name: string, spawnIndex: number): Promise<Types.Killer> {
		debug(`[${script.Name}] SpawnKiller() name=${name}, spawnIndex=${spawnIndex}`);

		if (name === "*") {
			error("Bulk spawn not allowed from this API.");
		} else if (name === "**") {
			const pick = this.KillerTemplates[math.random(0, this.KillerTemplates.size() - 1)];
			info(`[${script.Name}] SpawnKiller() special '**' picked: ${pick.Name}`);
			return this.spawn(pick.Name, spawnIndex);
		} else {
			return this.spawn(name, spawnIndex);
		}
	}

	public async SpawnKillers(names: string[], spawnIndex: number): Promise<Types.Killer[]> {
		const killers: Types.Killer[] = [];
		const errors: string[] = [];

		for (const name of names) {
			try {
				const k = await this.SpawnKiller(name, spawnIndex);
				killers.push(k);
			} catch (e) {
				errors.push(tostring(e));
				warn(`[${script.Name}] SpawnKillers() failed for "${name}": ${tostring(e)}`);
			}
		}

		if (killers.size() > 0) return killers;
		warn(`${names}, ${spawnIndex}`);
		throw `All ${errors.size()} killer spawns failed: ${errors.join(", ")}`;
	}

	public async SpawnAll(spawnIndex: number): Promise<Types.Killer[]> {
		debug(`[${script.Name}] SpawnAll() spawnIndex=${spawnIndex}`);

		return this.SpawnKillers(this.GetKillersName(false), spawnIndex);
	}
}
