script.Parent.Humanoid.Died:Connect(function()
	if not game.ReplicatedStorage.SavedPlayers.NeutralPlayers:FindFirstChild(script.Parent.Name) then
		if game.ReplicatedStorage.SavedPlayers.SurvivedPlayers:FindFirstChild(script.Parent.Name) then
			local GotDate
			local GotExactDate
			local Date = os.date("*t")
			local Months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
			for i, Month in pairs(Months) do
				if Date.month == i then
					GotDate = Month.."/"..Date.day.."/"..Date.year
				end
			end
			GotExactDate = Date.hour..":"..Date.min..":"..Date.sec
			
			warn("["..GotDate.." --- "..GotExactDate.."]".."[CHANGING PARENT] Trying to set a new parent "..script.Parent.Name.." > "..game.ReplicatedStorage.SavedPlayers.DiedPlayers:GetFullName()..".")
			game.ReplicatedStorage.RemoteEvents.DiedEvent:FireServer(game.ReplicatedStorage.SavedPlayers.DiedPlayers)
		end
	end
end)