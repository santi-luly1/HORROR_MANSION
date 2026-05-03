-- OnyxUI_ComponentsDemo.story
local Fusion = require("@packages/fusion")
local OnyxUI = require("@packages/onyx-ui")

local Components = OnyxUI.Components
local Themer = OnyxUI.Themer
local Children = Fusion.Children

local controls = {
	BackgroundColor = Color3.fromRGB(25, 25, 25),
	ShowAllComponents = true,
}

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props)
		local scope = props.scope:innerScope(Fusion, Components, OnyxUI.Util)
		local Theme = Themer.Theme:now()

		scope:Scroller {
			Parent = props.target,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = props.controls.BackgroundColor,
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = Theme.Colors.Primary.Main,

			[Children] = {
				-- Base components - use Position instead of LayoutOrder
				scope:Text {
					Text = "OnyxUI Components Demo",
					Font = Enum.Font.GothamBold,
					TextSize = 24,
					TextColor3 = Theme.Colors.Neutral[0],
					Position = UDim2.fromOffset(20, 20),
					Size = UDim2.fromOffset(300, 30),
				},

				-- Button
				scope:Button {
					Content = { "Click Me" },
					Position = UDim2.fromOffset(20, 60),
					Size = UDim2.fromOffset(120, 35),
				},

				-- IconButton
				scope:IconButton {
					Image = "rbxassetid://10814531047",
					Position = UDim2.fromOffset(160, 60),
					Size = UDim2.fromOffset(35, 35),
				},

				-- Badge
				scope:Badge {
					Content = { "NEW" },
					Color = Theme.Colors.Success.Main,
					Position = UDim2.fromOffset(210, 60),
					Size = UDim2.fromOffset(50, 20),
				},

				-- Row 2: Checkbox, Switch, TextInput
				scope:Checkbox {
					Position = UDim2.fromOffset(20, 110),
					Size = UDim2.fromOffset(25, 25),
				},

				scope:Switch {
					Position = UDim2.fromOffset(70, 110),
					Size = UDim2.fromOffset(45, 25),
				},

				scope:TextInput {
					PlaceholderText = "Type here...",
					Size = UDim2.fromOffset(200, 35),
					Position = UDim2.fromOffset(130, 110),
				},

				-- Row 3: TextArea, ProgressBar, Avatar
				scope:TextArea {
					PlaceholderText = "Multi-line text area",
					Size = UDim2.fromOffset(200, 60),
					Position = UDim2.fromOffset(20, 160),
				},

				scope:ProgressBar {
					Progress = 0.75,
					Size = UDim2.fromOffset(200, 8),
					Color = Theme.Colors.Primary.Main,
					Position = UDim2.fromOffset(240, 160),
				},

				scope:Avatar {
					Image = "rbxthumb://type=AvatarHeadShot&id=1&w=150&h=150",
					Size = UDim2.fromOffset(60, 60),
					Position = UDim2.fromOffset(460, 160),
				},

				-- Row 4: TitleBar, Icon, IconText, Heading
				scope:TitleBar {
					Content = { "Title Bar Example" },
					Position = UDim2.fromOffset(20, 240),
					Size = UDim2.fromOffset(200, 30),
				},

				scope:Icon {
					Image = "rbxassetid://10814531047",
					Size = UDim2.fromOffset(32, 32),
					Position = UDim2.fromOffset(240, 240),
				},

				scope:IconText {
					Content = { "Icon + Text" },
					Position = UDim2.fromOffset(290, 240),
					Size = UDim2.fromOffset(120, 30),
				},

				scope:Heading {
					Text = "Heading Component",
					Position = UDim2.fromOffset(430, 240),
					Size = UDim2.fromOffset(150, 30),
				},

				-- Row 5: TextSwap, Slider, Tabs
				scope:TextSwap {
					Content = { "Text 1", "Text 2" },
					Position = UDim2.fromOffset(20, 290),
					Size = UDim2.fromOffset(100, 30),
				},

				scope:Slider {
					Value = scope:Value(50),
					Min = 0,
					Max = 100,
					Size = UDim2.fromOffset(200, 20),
					Position = UDim2.fromOffset(140, 290),
				},

				scope:Tabs {
					Tabs = {
						{ "Tab 1" },
						{ "Tab 2" },
						{ "Tab 3" },
					},
					Tab = 1,
					Size = UDim2.fromOffset(200, 30),
					Position = UDim2.fromOffset(360, 290),
				},

				-- Row 6: Card, Frame, Group
				scope:Card {
					Size = UDim2.fromOffset(150, 100),
					Position = UDim2.fromOffset(20, 340),
					[Children] = {
						scope:Text {
							Text = "Card Content",
							Size = UDim2.fromScale(1, 1),
						},
					},
				},

				scope:Frame {
					Size = UDim2.fromOffset(100, 100),
					BackgroundColor3 = Theme.Colors.Primary.Main,
					Position = UDim2.fromOffset(190, 340),
					Corner = { Enabled = true, Radius = UDim.new(0, 10) },
					Stroke = { Enabled = true, Thickness = 2, Color = Theme.Colors.Neutral[0] },
					Gradient = {
						Enabled = true,
						Color = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(0, 0, 1)),
						Rotation = 45,
					},
				},

				scope:Group {
					Size = UDim2.fromOffset(200, 50),
					Position = UDim2.fromOffset(310, 340),
					[Children] = {
						scope:Text {
							Text = "Group Content",
							Size = UDim2.fromScale(1, 1),
						},
					},
				},

				-- Row 7: Scroller, Divider, AutoScaler, Image
				scope:Scroller {
					Size = UDim2.fromOffset(150, 100),
					Position = UDim2.fromOffset(20, 460),
					[Children] = {
						scope:Frame {
							Size = UDim2.fromOffset(300, 50),
							BackgroundColor3 = Theme.Colors.Success.Main,
						},
					},
				},

				scope:Divider {
					Size = UDim2.fromOffset(200, 2),
					Position = UDim2.fromOffset(190, 460),
				},

				scope:AutoScaler {
					Size = UDim2.fromOffset(100, 50),
					Position = UDim2.fromOffset(190, 480),
					[Children] = {
						scope:Text {
							Text = "Auto Scaled",
							Size = UDim2.fromScale(1, 1),
						},
					},
				},

				scope:Image {
					Image = "rbxassetid://10814531047",
					Size = UDim2.fromOffset(64, 64),
					Position = UDim2.fromOffset(310, 460),
				},

				scope:Button(OnyxUI.Util.CombineProps(props, {
					Name = script.Name,
					Content = { "Test" },
					Color = Theme.Colors.Primary.Main,
					SizeVariant = "Large",
					Size = scope:UDim2(0, Theme.Sizing["8"]),
					List = {
						FillDirection = Enum.FillDirection.Vertical,
					},
				})),
			},
		}
	end,
}

return story
