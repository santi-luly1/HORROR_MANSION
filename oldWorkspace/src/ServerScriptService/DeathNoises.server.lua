function Died(p)
	local tracks = script:GetChildren()
	local rn = math.random(1,#tracks)
	local track = tracks[rn]
	
	if track ~= nil then
		track:Play()
		wait(track.TimeLength)
		track:Pause()
	end
end

function Hum(c)
	local hum = c:FindFirstChild("Humanoid")
	
	if hum ~= nil then
		hum.Died:Connect(function(hum) Died(c) end)
	end
end

function Enter(p)
	p.CharacterAdded:Connect(Hum)
end

game.Players.PlayerAdded:Connect(Enter)
