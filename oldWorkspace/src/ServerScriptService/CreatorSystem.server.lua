local RS = game.ReplicatedStorage
local FT = require(RS.Modules.GameFunctions)
local Settings = require(RS.Modules.GameSettings)
local DayBool = Settings.CreatorPanel.Day
local Heartbeat = game["Run Service"].Heartbeat

RS.RemoteEvents.CreatorPanelEvents.OnServerEvent:Connect(function(player, Type, NumberValues)
	local globalS, global_eM = pcall(function()
		if Type == "Fog" then
			warn("Setting", Type, "to", NumberValues,".")
			for FOG = game.Lighting.FogEnd, NumberValues do
				game.Lighting.FogEnd = FOG
				Heartbeat:Wait()
			end
		elseif Type == "SetTime" then
			warn("Setting game time:", tonumber(NumberValues))
			Settings.Main.GameTimer.Base = NumberValues
		elseif Type == "SetDayNight" then
			warn("Setting time to", tostring(DayBool))
			if DayBool then
				delay(.01, function()
					for Light = game.Lighting.Brightness, 0, -1 do
						game.Lighting.Brightness = Light
						Heartbeat:Wait()
					end
				end)
				delay(.02, function()
					for DayTime = game.Lighting.ClockTime, 0, -1 do
						game.Lighting.ClockTime = DayTime
						Heartbeat:Wait()
					end
				end)
				DayBool = false
			else
				DayBool = true
				delay(.01, function()
					for Light = game.Lighting.Brightness, 2, .5 do
						game.Lighting.Brightness = Light
						Heartbeat:Wait()
					end
				end)
				delay(.02, function()
					for DayTime = game.Lighting.ClockTime, 14, 1 do
						game.Lighting.ClockTime = DayTime
						Heartbeat:Wait()
					end
				end)
			end
		elseif Type == "EndGame" then
			FT.endGame()
		end
		
		local s, errorMessage = pcall(function()
			for _, plrs in pairs(RS.SavedPlayers:GetDescendants()) do
				if plrs:IsA'IntValue' and player.UserId ~= plrs.Value then
					for _, players in pairs(game.Players:GetPlayers()) do
						if players.UserId ~= plrs.Value then
							local panel = players.PlayerGui.CreatorPanel.Content.Main
							
							panel.TextBoxes.Fog.Text = tostring(game.Lighting.FogEnd)
							panel.TextBoxes.GameTime.Text = tostring(Settings.Main.GameTimer.Base)
						end
					end
				end
			end
		end)
		if not s then warn("Error in the creator panel:", errorMessage) end
	end)
	
	if not globalS then warn("Error in the Creator Panel main script: "..global_eM) end
end)