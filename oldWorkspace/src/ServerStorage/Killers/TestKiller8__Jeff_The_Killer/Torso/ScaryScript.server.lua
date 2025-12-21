Dra = script.Parent.Scream
Sind = script.Parent.Boom
Popup = script.Parent.ONO
Ready = true
function onTouch(hit)
	local h = hit.Parent:FindFirstChild("Humanoid")
	if h ~= nil and Ready == true then
		Ready = false
		local plyr = game.Players:FindFirstChild(h.Parent.Name)
		local c = Popup:clone()
		c.Parent = plyr.PlayerGui
		script.Parent.Boom:Play()
		h.Health -= 20
		wait(1)
		c:remove()
		wait(1)
		Ready = true
	end
end

script.Parent.Touched:connect(onTouch)
