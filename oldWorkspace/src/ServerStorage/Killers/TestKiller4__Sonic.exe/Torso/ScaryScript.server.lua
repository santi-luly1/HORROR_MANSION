Sound = script.Parent.Luagh
Popup = script.Parent.Popup
Ready = true

function onTouch(hit)
	local h = hit.Parent:FindFirstChild("Humanoid")
	if h ~= nil and Ready then
		Ready = false
		local plr = game.Players:GetPlayerFromCharacter(h.Parent)
		local c = Popup:clone()
		--c.Parent = plr.PlayerGui
		script.Parent.Luagh:play()
		wait(1)
		c:remove()
		wait(1)
		Ready = true
	end
end

script.Parent.Touched:connect(onTouch)
