--!strict
local Fusion = require("@game/ReplicatedStorage/Packages/fusion")
local OnyxUI = require("@game/ReplicatedStorage/Packages/onyx-ui")

local Themer = OnyxUI.Themer
local Util = OnyxUI.Util

local Scope = Fusion.scoped(Fusion)

local CrimsonFog = Themer.NewTheme(Scope, {
	Colors = {
		Primary = {
			Main = Util.Colors.Red["500"],
		},
		Secondary = {
			Main = Util.Colors.Rose["300"],
		},
		Accent = {
			Main = Util.Colors.Orange["400"],
		},

		Neutral = {
			Main = Util.Colors.Stone["800"],
		},
		NeutralContent = {
			Main = Util.Colors.Stone["200"],
		},

		Base = {
			Main = Util.Colors.Zinc["900"],
		},
		BaseContent = {
			Main = Util.Colors.Stone["50"],
		},

		Success = {
			Main = Util.Colors.Emerald["400"],
		},
		Error = {
			Main = Util.Colors.Red["500"],
		},
		Warning = {
			Main = Util.Colors.Amber["500"],
		},
		Info = {
			Main = Util.Colors.Sky["400"],
		},
	},
	Font = {
		Body = Enum.Font.SourceSans :: any,
		Heading = Enum.Font.Michroma :: any,
		Monospace = Enum.Font.JosefinSans :: any,
	},
	FontWeight = {
		Body = Enum.FontWeight.Medium :: any,
		Bold = Enum.FontWeight.Bold :: any,
		Heading = Enum.FontWeight.ExtraBold :: any,
	},
	TextSize = {
		Base = 18,
	},
	CornerRadius = {
		Base = 7,
	},
	StrokeThickness = {
		Base = 1.5,
	},
	StrokeEmphasis = {
		Regular = 0.24,
	},
	Spacing = {
		Base = 20,
	},
	Sizing = {
		Base = 21,
	},
	Padding = {
		Base = 22,
	},
	SpringSpeed = {
		Base = 44,
	},
	SpringDampening = {
		Base = 0.95,
	},
	Sound = {},
	Emphasis = {},
})

return CrimsonFog
