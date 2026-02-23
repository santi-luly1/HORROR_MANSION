--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
local Fusion = require(Packages:WaitForChild("fusion"))

local Themer = OnyxUI.Themer
local Util = OnyxUI.Util

local Scope = Fusion.scoped(Fusion)

local ColdDawn = Themer.NewTheme(Scope, {
	Colors = {
		Primary = {
			Main = Util.Colors.Cyan["500"],
		},
		Secondary = {
			Main = Util.Colors.Blue["300"],
		},
		Accent = {
			Main = Util.Colors.Indigo["400"],
		},

		Neutral = {
			Main = Util.Colors.Slate["700"],
		},
		NeutralContent = {
			Main = Util.Colors.Slate["200"],
		},

		Base = {
			Main = Util.Colors.Slate["900"],
		},
		BaseContent = {
			Main = Util.Colors.Slate["50"],
		},

		Success = {
			Main = Util.Colors.Teal["400"],
		},
		Error = {
			Main = Util.Colors.Rose["500"],
		},
		Warning = {
			Main = Util.Colors.Yellow["500"],
		},
		Info = {
			Main = Util.Colors.Sky["400"],
		},
	},
	Font = {
		Body = Enum.Font.Ubuntu :: any,
		Heading = Enum.Font.GothamBold :: any,
		Monospace = Enum.Font.Bodoni :: any,
	},
	FontWeight = {
		Body = Enum.FontWeight.Regular :: any,
		Bold = Enum.FontWeight.Bold :: any,
		Heading = Enum.FontWeight.SemiBold :: any,
	},
	TextSize = {
		Base = 17,
	},
	CornerRadius = {
		Base = 6,
	},
	StrokeThickness = {
		Base = 1,
	},
	StrokeEmphasis = {
		Regular = 0.2,
	},
	Spacing = {
		Base = 21,
	},
	Sizing = {
		Base = 22,
	},
	Padding = {
		Base = 20,
	},
	SpringSpeed = {
		Base = 48,
	},
	SpringDampening = {
		Base = 1,
	},
	Sound = {},
	Emphasis = {},
})

return ColdDawn
