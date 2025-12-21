local Event = game.ReplicatedStorage.RemoteEvents.CreatorPanelEvents

local function Fog()
	warn("[Creator Panel] Trying to set new fog")
	Event:FireServer("Fog", tonumber(script.Parent.TextBoxes.Fog.Text))
end
local function SetTime()
	warn("[Creator Panel] Trying to set a new game time")
	Event:FireServer("SetTime", tonumber(script.Parent.TextBoxes.GameTime.Text))
end
local function setDayNight()
	warn("[Creator Panel] Trying to change the time")
	Event:FireServer("SetDayNight")
end
local function EndGame()
	warn("[Creator Panel] Ending game.")
	Event:FireServer("EndGame")
end

script.Parent.TextBoxes.Fog.FocusLost:Connect(Fog)
script.Parent.TextBoxes.GameTime.FocusLost:Connect(SetTime)
script.Parent.Buttons.DayNight.MouseButton1Click:Connect(setDayNight)
script.Parent.Buttons.EndGame.MouseButton1Click:Connect(EndGame)