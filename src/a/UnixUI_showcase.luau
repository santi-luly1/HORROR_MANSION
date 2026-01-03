-- LocalScript in StarterGui
-- Simple OnyxUI demo that works with standard Roblox events

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Fusion"))
local OnyxUI = require(ReplicatedStorage:WaitForChild("OnyxUI"))

-- Get components
local Components = OnyxUI.Components
local Util = OnyxUI.Util
local Scope = Fusion.scoped(Fusion, Components)

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleOnyxUIDemo"
screenGui.Parent = PlayerGui

-- Simple state
local clickCount = 0

-- FIXED: Create Fusion reactive values
local progressValue = Scope:Value(0.75) -- Initial progress value

-- Main container frame with visible background
local mainFrame = Scope:Frame {
    Parent = screenGui,
    Size = UDim2.new(0, 300, 0, 280),
    Position = UDim2.new(0.5, -150, 0.5, -140),
    BackgroundColor3 = Color3.fromRGB(45, 45, 45),
    BackgroundTransparency = 0,
    Visible = true,
}

-- Title
local title = Scope:Text {
    Parent = mainFrame,
    Text = "OnyxUI Demo",
    Position = UDim2.new(0.5, 0, 0, 20),
    AnchorPoint = Vector2.new(0.5, 0),
    Font = Enum.Font.FredokaOne,
    TextSize = 24,
    Color = Util.Colors.Blue["500"],
}

-- Create Button component (this returns the actual Roblox instance)
local myButton = Scope:Button {
    Parent = mainFrame,
    Content = {"Click Me!"},
    Position = UDim2.new(0.5, 0, 0, 60),
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0, 120, 0, 35),
    Color = Util.Colors.Green["500"],
    BackgroundTransparency = 0,
}

-- Click counter text
local counterText = Scope:Text {
    Parent = mainFrame,
    Text = "Clicks: 0",
    Position = UDim2.new(0.5, 0, 0, 105),
    AnchorPoint = Vector2.new(0.5, 0),
    Font = Enum.Font.SourceSansBold,
}

-- Checkbox
local checkboxLabel = Scope:Text {
    Parent = mainFrame,
    Text = "Enable Feature:",
    Position = UDim2.new(0, 20, 0, 140),
    Font = Enum.Font.SourceSans,
}

local myCheckbox = Scope:Checkbox {
    Parent = mainFrame,
    Position = UDim2.new(0, 120, 0, 140),
    Color = Util.Colors.Blue["500"],
    BackgroundTransparency = 0,
}

-- Text Input
local inputLabel = Scope:Text {
    Parent = mainFrame,
    Text = "Your Name:",
    Position = UDim2.new(0, 20, 0, 180),
    Font = Enum.Font.SourceSans,
}

local nameInput = Scope:TextInput {
    Parent = mainFrame,
    Position = UDim2.new(0, 100, 0, 180),
    Size = UDim2.new(0, 180, 0, 30),
    PlaceholderText = "Enter name...",
    BackgroundTransparency = 0,
}

-- Progress Bar - FIXED: Using reactive Fusion value
local progressLabel = Scope:Text {
    Parent = mainFrame,
    Text = "Loading Progress:",
    Position = UDim2.new(0, 20, 0, 230),
    Font = Enum.Font.SourceSans,
}

local progressBar = Scope:ProgressBar {
    Parent = mainFrame,
    Position = UDim2.new(0, 20, 0, 250),
    Size = UDim2.new(1, -40, 0, 20),
    Progress = progressValue, -- FIXED: Using Fusion reactive value
    Color = Util.Colors.Blue["500"],
}

print("Simple OnyxUI demo loaded!")

-- Connect to actual Roblox events after components are created
-- Wait a frame to ensure components are fully created
task.wait()

-- Find the actual button instance and connect to its events
local buttonInstance = nil
for _, child in ipairs(mainFrame:GetChildren()) do
    if child:IsA("TextButton") or child:IsA("ImageButton") then
        -- This is likely our button
        buttonInstance = child
        break
    end
end

if buttonInstance then
    print("Found button instance:", buttonInstance.Name)
    
    -- Connect to the standard Roblox button event
    buttonInstance.MouseButton1Click:Connect(function()
        clickCount = clickCount + 1
        print("Button clicked! Count:", clickCount)
        
        -- Update the counter text
        counterText.Text = "Clicks: " .. tostring(clickCount)
        
        -- FIXED: Update progress value using Fusion reactive system
        local currentProgress = Fusion.peek(progressValue)
        local newProgress = (currentProgress + 0.1) % 1
        progressValue:set(newProgress)
        print("Progress updated to:", newProgress)
    end)
    
    -- Also try Activated event as backup
    buttonInstance.Activated:Connect(function()
        print("Button activated!")
    end)
else
    warn("Could not find button instance!")
end

-- Find and connect checkbox
local checkboxInstance = nil
for _, child in ipairs(mainFrame:GetChildren()) do
    if child:IsA("TextButton") or child:IsA("ImageButton") then
        -- Check if this might be the checkbox (could be multiple buttons)
        if child.Position.Y.Offset == 140 then -- Our checkbox Y position
            checkboxInstance = child
            break
        end
    end
end

if checkboxInstance then
    print("Found checkbox instance:", checkboxInstance.Name)
    
    local isChecked = false
    checkboxInstance.MouseButton1Click:Connect(function()
        isChecked = not isChecked
        print("Checkbox clicked! Checked:", isChecked)
    end)
else
    warn("Could not find checkbox instance!")
end

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