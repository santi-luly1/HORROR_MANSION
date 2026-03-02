local StarterPlayer = game:GetService("StarterPlayer")
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")

local Fusion = require(Packages:WaitForChild("fusion"))
local Maid = require(Packages:WaitForChild("maid"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Themes = require(StarterPlayer.StarterPlayerScripts.Client.UI.Themes)

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type FusionTheme = OnyxUI.Theme

export type MapData = {
	Name: string,
	Thumbnail: string,
	DisplayName: string,
}

export type UI = {
	-- lifecycle
	Init: (self: UI) -> (),
	Start: (self: UI) -> GuiBase,
	Stop: (self: UI) -> (),
	SetTheme: (self: UI, theme: FusionTheme) -> (),
	SetThemeByName: (self: UI, themeName: string) -> boolean,

	-- private
	_init: boolean,
	_start: boolean,
	_scope: Fusion.Scope<any>,
	_currentTheme: Fusion.Value<Themes.ThemeSpec>,
	_maid: Maid.Maid,
	_shopEnabled: Fusion.Value<boolean>,
	_purchaseStatus: Fusion.Value<string>,
	_purchaseStatusColor: Fusion.Value<Color3>,
	_activeTab: Fusion.Value<number>,
	_pointsCount: Fusion.Value<number>,
	_survivalsCount: Fusion.Value<number>,
	_selectedItem: Fusion.Value<string>,
	_mapOptions: Fusion.Value<{ MapData }>,
	_votes: Fusion.Value<{ [string]: number }>,
	_votingTimer: Fusion.Value<number>,
	_votingWinner: Fusion.Value<string?>,
	_votingVisible: Fusion.Value<boolean>,

	-- private methods
	_buildContent: (self: UI) -> Frame,
	_onSelectItem: (self: UI, itemName: string) -> (),
	_handlePurchase: (self: UI) -> (),
}

return (nil :: any) :: UI
