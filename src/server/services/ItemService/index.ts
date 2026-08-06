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
		26/07/16 --> Implemented logger.
		26/08/03 --> Removed promises from "unnecessary" places.
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
import { debug, info, warn } from "@rbxts/logger";
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
	private activeItems = new Map<Tool, Types.ActiveItem>();

	private ItemsFolder = ServerStorage.WaitForChild("Items", 30) as Folder;
	private purchaseCheck = t.strictArray(t.instanceOf("Player"), t.string);

	public ItemPurchased = new Signal<(player: Player, itemName: string) => void>();
	public ItemEquipped = new Signal<(player: Player, itemName: string) => void>();

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
		if (!item) return undefined;

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
	public onInit() {}

	public onStart() {
		Workspace.DescendantAdded.Connect((descendant) => {
			// this is too expensive, update me later
			if (!descendant.IsA("Tool")) return;

			const tool = descendant as Tool;
			const player = Players.GetPlayerFromCharacter(tool.Parent as Model);
			if (player) this.setupTool(tool, player);
		});

		Netwoking.Server.Get("PurchaseItem").SetCallback(async (player: Player, itemName: string) => {
			if (!RunService.IsRunning()) return `Successfully purchased ${itemName}`; // story

			try {
				return await this.PurchaseItem(player, itemName);
			} catch (e) {
				const msg = tostring(e);
				warn(`[${script.Name}] Purchase failed: ${player.Name} / ${itemName} / ${msg}`);
				return msg;
			}
		});

		Netwoking.Server.Get("GetAvailableItems").SetCallback(() => {
			return this.GetAvailableItems();
		});

		Netwoking.Server.Get("GetItemData").SetCallback((_, itemName: string) => {
			return this.GetItemData(itemName);
		});

		Players.PlayerRemoving.Connect((player: Player) => {
			debug(`[${script.Name}] PlayerRemoving: ${player.Name}`);
			for (const [tool, data] of pairs(this.activeItems)) {
				if (data.Player === player) this.cleanupTool(tool);
			}
		});

		Players.PlayerAdded.Connect((player: Player) => {
			debug(`[${script.Name}] PlayerAdded: ${player.Name}`);
			this.PlayerDataService.ProfileLoaded.Once((plr: Player) => {
				if (plr !== player) return;

				debug(`[${script.Name}] ProfileLoaded: ${player.Name} -> purchasing starter flashlight`);
				this.PurchaseItem(player, "Flashlight"); // starter flashlight
			});
		});
	}

	/*
	--------------------------------------------------------------------
	--- Private Methods
	--------------------------------------------------------------------
	*/
	private setupTool(tool: Tool, player: Player) {
		const itemData = this.getItemData(tool.Name);
		if (!itemData || this.activeItems.get(tool)) return;

		debug(`[${script.Name}] setupTool: ${player.Name} -> ${tool.Name}`);

		const behavior = SpecialItemBehavior.Get(tool.Name);
		const [, itemBehavior] = xpcall(
			() => {
				debug(`[${script.Name}] Creating behavior instance: ${tool.Name}`);
				return new behavior(tool);
			},
			(e) => warn(`${tool.Name}'s behavior has encoutered an warn:\n${e}`),
		);

		if (itemBehavior === undefined) return;

		const trove = new Trove();
		const activeItem: Types.ActiveItem = {
			Tool: tool,
			Player: player,
			Behavior: itemBehavior,
			Trove: trove,
		};

		itemBehavior.Setup();
		debug(`[${script.Name}] Behavior.Setup complete: ${tool.Name}`);

		this.activeItems.set(tool, activeItem);

		trove.add(
			tool.AncestryChanged.Connect(() => {
				debug(`[${script.Name}] Tool AncestryChanged: ${player.Name} -> ${tool.Name}`);
				if (!tool.IsDescendantOf(Workspace) && !tool.IsDescendantOf(player)) this.cleanupTool(tool);
			}),
		);

		// REVIEW: "ItemGranted" and "ItemEquipped"? kinda confusing.
		Netwoking.Server.Get("ItemGranted").SendToPlayer(player, tool); // re-fire, since the client has already cleared its connections, it needs to remake them.
		info(`[${script.Name}] ItemEquipped: ${player.Name} -> ${tool.Name}`);
		this.ItemEquipped.Fire(player, tool.Name);
	}

	private cleanupTool(tool: Tool) {
		const activeItem = this.activeItems.get(tool);
		if (!activeItem) return;

		debug(`[${script.Name}] cleanupTool: ${activeItem.Player.Name} -> ${tool.Name}`);
		activeItem.Trove.clean();
		this.activeItems.delete(tool);
	}

	/*
	--------------------------------------------------------------------
	--- Public API
	--------------------------------------------------------------------
	*/
	public async PurchaseItem(player: Player, itemName: string): Promise<string> {
		assert(this.purchaseCheck([player, itemName]));

		debug(`[${script.Name}] PurchaseItem called: ${player.Name} -> ${itemName}`);

		// Validate
		const itemData = this.getItemData(itemName);
		if (!itemData) {
			warn(`[${script.Name}] Invalid item purchase attempt: ${player.Name} / ${itemName}`);
			throw "Item does not exist";
		}

		if (this.HasItem(player, itemName)) {
			warn(`[${script.Name}] Duplicate purchase attempt: ${player.Name} / ${itemName}`);
			throw "Item already bought";
		}

		const points = await this.PlayerDataService.GetPlayerData(player).then((data) => data.Points);

		if (points < itemData.Price) {
			warn(
				`[${script.Name}] Insufficient points: ${player.Name} / ${itemName} / need ${itemData.Price}, have ${points}`,
			);
			throw "Insufficient points";
		}

		await this.PlayerDataService.UpdatePlayerStat(player, "Points", -itemData.Price);

		const tool = this.ItemsFolder.FindFirstChild(itemData.Name)!.Clone() as Tool;
		tool.Parent = player.FindFirstChild("StarterGear")!;

		const backpackTool = tool.Clone();
		backpackTool.Parent = player.FindFirstChild("Backpack")!;

		this.ItemPurchased.Fire(player, itemData.Name);
		Netwoking.Server.Get("ItemGranted").SendToPlayer(player, backpackTool);

		info(`[${script.Name}] Purchased: ${player.Name} / ${itemData.Name} (-${itemData.Price} pts)`);
		return `Successfully purchased ${itemName}`;
	}

	public GetItemData(itemName: string): Types.ItemData | undefined {
		return this.getItemData(itemName);
	}

	public HasItem(player: Player, itemName: string): boolean {
		return player.FindFirstChild("StarterGear")!.FindFirstChild(itemName) !== undefined;
	}

	public IsValidItem(itemName: string): boolean {
		return this.getItemData(itemName) !== undefined;
	}

	public GetAvailableItems(): string[] {
		const names: string[] = [];
		for (const item of this.ItemsFolder.GetChildren()) names.push(item.Name);

		return names;
	}
}
