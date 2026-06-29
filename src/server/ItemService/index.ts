/*
[=[
    @class ItemService
    @author santi-luly1
    @description Server-side item manager for players.

    CHANGELOG: [
        26/02/14 --> Initial version of the module.
        26/02/24 --> Added SpecialItemBehavior support (smth like SpecialKillerBehavior).
        26/02/25 --> Auto-purchase flashlight on join.
		26/06/29 --> Parsed into roblox-ts.
    ]
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
// Roblox services
import { Players, RunService, ServerStorage, Workspace } from "@rbxts/services";

// Packages
import { Service, OnInit, OnStart } from "@flamework/core";
import { t } from "@rbxts/t";
import { Trove } from "@rbxts/trove";
import Promise from "@rbxts-js/roblox-lua-promise";
import Signal from "@rbxts/signal";

// Types
import * as PlayerDataServiceTypes from "server/types/PlayerDataService";
import * as Types from "server/types/ItemService";

// Networking
import Netwoking from "shared/networking/ItemServiceNetwork";

// Local utilities
import SpecialItemBehavior from "./SpecialItemBehavior";

// Services
import PlayerDataService from "server/services/PlayerDataService";

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export default class ItemServiceClass implements OnInit, OnStart {
	/*
		runtime fields
	*/

	private init = false;
	private start = false;
	private activeItems = new Map<Tool, Types.ActiveItem>();

	private ItemsFolder = ServerStorage.WaitForChild("Items");
	private purchaseCheck = t.strictArray(t.instanceOf("Player"), t.string);

	public ItemPurchased = new Signal();
	public ItemEquipped = new Signal();
	public ItemUsed = new Signal();

	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/

	/*
	--------------------------------------------------------------------
	--- Helpers
	--------------------------------------------------------------------
	*/
	private getItemData(itemName: string): Types.ItemData | undefined {
		const item = this.ItemsFolder.FindFirstChild(itemName) as Tool;
		if (!item) {
			return undefined;
		}

		return {
			Name: item.Name,
			Price: (item.GetAttribute("Price") as number | undefined) ?? 0,
			TextureId: item.TextureId !== "" ? item.TextureId : "rbxassetid://13239978994", // PLACE HOLDER ID
		};
	}

	/*
	--------------------------------------------------------------------
	--- Constructor
	--------------------------------------------------------------------
	*/
	constructor(private readonly PlayerDataService: PlayerDataService) {}

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public onInit() {
		assert(!this.init, `[${script.Name}] - Module already initialized.`);
		this.init = true;

		this.ItemPurchased = new Signal();
		this.ItemEquipped = new Signal();
		this.ItemUsed = new Signal();

		SpecialItemBehavior.Init();

		Workspace.DescendantAdded.Connect((descendant) => {
			if (!descendant.IsA("Tool")) return;

			const tool = descendant as Tool;
			const player = Players.GetPlayerFromCharacter(tool.Parent as Model);
			if (player) {
				this._setupTool(tool, player);
			}
		});

		Netwoking.Server.Get("PurchaseItem").SetCallback((player: Player, itemName: string) => {
			if (!RunService.IsRunning()) return `Successfully purchased {itemName}`; // story

			let status: string;
			this.PurchaseItem(player, itemName)
				.andThen((info: string) => {
					status = info;
				})
				.catch((e: string) => {
					status = e;
				})
				.await();

			return status;
		});

		Netwoking.GetAvailableItems.OnServerInvoke = () => {
			return this.GetAvailableItems();
		};

		Netwoking.GetItemData.OnServerInvoke = (_: Player, itemName: string) => {
			const data = this.GetItemData(itemName);
			return data ?? nil;
		};

		Players.PlayerRemoving.Connect((player: Player) => {
			for (const [tool, data] of pairs(this.activeItems)) {
				if (data.Player === player) {
					this._cleanupTool(tool);
				}
			}
		});
	}

	public onStart() {
		assert(this.init, `[${script.Name}] - Module not initialized.`);
		assert(!this.start, `[${script.Name}] - Module already started.`);
		this.start = true;

		Players.PlayerAdded.Connect((player: Player) => {
			this.PlayerDataService.ProfileLoaded.Once((plr: Player) => {
				if (plr !== player) {
					return;
				}

				this.PurchaseItem(player, "Flashlight").catch(warn); // starter flashlight
			});
		});
	}

	/*
	--------------------------------------------------------------------
	--- Private Methods
	--------------------------------------------------------------------
	*/
	private _setupTool(tool: Tool, player: Player) {
		const itemData = this.getItemData(tool.Name);
		if (!itemData) {
			return;
		}

		if (this.activeItems[tool]) {
			return;
		}

		const maid = Trove.new();
		const behavior = SpecialItemBehavior.Get(tool.Name);

		xpcall(
			() => {
				behavior(tool, player, maid);
			},
			(e) => {
				warn(`{tool.Name}'s behavior has encoutered an error:\n{e}`);
			},
		);

		const activeItem: Types.ActiveItem = {
			Tool: tool,
			Player: player,
			Behavior: behavior,
			Trove: maid,
		};

		this.activeItems[tool] = activeItem;

		maid.GiveTask(
			tool.AncestryChanged.Connect(() => {
				if (
					!tool.IsDescendantOf(workspace) &&
					!tool.IsDescendantOf(player.Backpack) &&
					!tool.IsDescendantOf(player.StarterGear) &&
					!tool.IsDescendantOf(player.Character as Model) // silence LLS
				) {
					this._cleanupTool(tool);
				}
			}),
		);

		Netwoking.ItemGranted.FireClient(player, tool); // re-fire, since the client has already cleared its connections, so it need to remake them.
		this.ItemEquipped.Fire(player, tool.Name);
	}

	private _cleanupTool(tool: Tool) {
		const activeItem = this.activeItems[tool];
		if (!activeItem) {
			return;
		}

		activeItem.Maid.Destroy();
		this.activeItems[tool] = nil as unknown as Types.ActiveItem;
	}

	/*
	--------------------------------------------------------------------
	--- Public API
	--------------------------------------------------------------------
	*/
	public PurchaseItem(player: Player, itemName: string): Types.TypedPromise<string> {
		return Promise.new((resolve, reject, onCancel) => {
			if (onCancel(() => undefined) as unknown as boolean) {
				return;
			}

			const [ok, err] = this.purchaseCheck(player, itemName) as unknown as [boolean, string];
			if (!ok) {
				return reject(`[{script.Name}] {err}`);
			}

			// Validate
			const itemData = this.getItemData(itemName);
			if (!itemData) {
				return reject("Item does not exist");
			}

			if (this.HasItem(player, itemName)) {
				return reject("Item already bought");
			}

			const [, points]: [unknown, number] = this.PlayerDataService.GetPlayerData(player)
				.andThen((data: any) => {
					return data.Points;
				})
				.await(); // await or else this will be skipped (oopsie)

			if (points < itemData.Price) {
				return reject("Insufficient points");
			}

			this.PlayerDataService.UpdatePlayerStat(player, "Points", -itemData.Price).andThen(() => {
				const tool = this.ItemsFolder[itemData.Name].Clone() as Tool;
				tool.Parent = player.StarterGear;

				const backpackTool = tool.Clone() as Tool;
				backpackTool.Parent = player.Backpack; // so the player gets the item instantely instead of having to reset.

				//this._setupTool(backpackTool, player) -- nope, this should be automatically handled by ChildAdded event inside Init

				Netwoking.ItemGranted.FireClient(player, backpackTool);

				return resolve(`Successfully purchased {itemName}`);
			}, reject);
		});
	}

	public GetItemData(itemName: string): Types.ItemData | undefined {
		return this.getItemData(itemName);
	}

	public HasItem(player: Player, itemName: string): boolean {
		return player.StarterGear.FindFirstChild(itemName) !== nil;
	}

	public IsValidItem(itemName: string): boolean {
		return this.getItemData(itemName) !== nil;
	}

	public GetAvailableItems(): { string } {
		const names: string[] = [];
		for (const item of this.ItemsFolder.GetChildren()) {
			names.push((item as any).Name);
		}
		return names as unknown as { string };
	}
}
