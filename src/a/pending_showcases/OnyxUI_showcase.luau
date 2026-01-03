-- LocalScript in StarterGui
-- Simple OnyxUI demo that works with standard Roblox events

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Packages = game:GetService("ReplicatedStorage").Packages
local Fusion = require(Packages:WaitForChild("fusion"))
local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

-- Get components
local Components = OnyxUI.Components
local Util = OnyxUI.Util
local Children = Fusion.Children
local Scope = Fusion.scoped(Fusion, Components)

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleOnyxUIDemo"
screenGui.Parent = PlayerGui

-- Simple state
local clickCount = 0

-- FIXED: Create Fusion reactive values
local progressValue = Scope:Value(0.75) -- Initial progress value
local counterTextValue = Scope:Value("Clicks: 0")

Scope:Frame { -- Main container frame with visible background
	Parent = screenGui,
	Size = UDim2.fromOffset(300, 280),
	Position = UDim2.new(0.5, -150, 0.5, -140),
	BackgroundColor3 = Color3.fromRGB(45, 45, 45),
	BackgroundTransparency = 0,
	Visible = true,
	[Children] = {
		Scope:TitleBar { -- Title
			Content = {"OnyxUI Demo"},
			Position = UDim2.new(0.5, 0, 0, 20),
			AnchorPoint = Vector2.new(0.5, 0),
			Font = Enum.Font.FredokaOne,
			TextSize = 24,
			Color = Util.Colors.Blue["500"],
		},
		Scope:Button { -- Create Button component (this returns the actual Roblox instance)
			Content = { "Click Me!" },
			Position = UDim2.new(0.5, 0, 0, 60),
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(120, 35),
			Color = Util.Colors.Green["500"],
			BackgroundTransparency = 0,
            Text = counterTextValue,
			OnActivate = function()
				clickCount = clickCount + 1
				print("Button clicked! Count:", clickCount)

				-- Update the counter text
				counterTextValue:set(`Clicks: {clickCount}`)

				-- FIXED: Update progress value using Fusion reactive system
				local currentProgress = Fusion.peek(progressValue)
				local newProgress = (currentProgress + 0.1) % 1
				progressValue:set(newProgress)
				print("Progress updated to:", newProgress)
			end,
		},
		Scope:Text { -- Click counter text
			Text = "Clicks: 0",
			Position = UDim2.new(0.5, 0, 0, 105),
			AnchorPoint = Vector2.new(0.5, 0),
			Font = Enum.Font.SourceSansBold,
		},
		Scope:Text { -- Checkbox
			Text = "Enable Feature:",
			Position = UDim2.fromOffset(20, 140),
			Font = Enum.Font.SourceSans,
		},
		Scope:Checkbox {
			Position = UDim2.fromOffset(120, 140),
			Color = Util.Colors.Blue["500"],
			BackgroundTransparency = 0,
            OnActivate = function(...)
                print("Checkbox clicked! Checked:", ...)
            end
		},
		Scope:Text { -- Text Input
			Text = "Your Name:",
			Position = UDim2.fromOffset(20, 180),
			Font = Enum.Font.SourceSans,
		},
		Scope:TextInput {
			Position = UDim2.fromOffset(100, 180),
			Size = UDim2.fromOffset(180, 30),
			PlaceholderText = "Enter name...",
            CharacterLimit = 5,
			BackgroundTransparency = 0,
		},
		Scope:Text { -- Progress Bar - FIXED: Using reactive Fusion value
			Text = "Loading Progress:",
			Position = UDim2.fromOffset(20, 230),
			Font = Enum.Font.SourceSans,
		},
		Scope:ProgressBar {
			Position = UDim2.fromOffset(20, 250),
			Size = UDim2.new(1, -40, 0, 20),
			Progress = progressValue, -- FIXED: Using Fusion reactive value
			Color = Util.Colors.Blue["500"],
		},
	},
}

print("Simple OnyxUI demo loaded!")

-- FIXED: Animate progress bar using Fusion reactive system
task.spawn(function()
	while true do
		-- Animate from 0 to 100%
		for i = 0, 100 do
			progressValue:set(i / 100) -- FIXED: Use :set() to update Fusion value
			task.wait(0.05)
		end
		-- Animate back from 100% to 0%
		for i = 100, 0, -1 do
			progressValue:set(i / 100) -- FIXED: Use :set() to update Fusion value
			task.wait(0.05)
		end
	end
end)
