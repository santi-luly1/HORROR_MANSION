while wait(math.random(.003, 4)) do
	for _, lights in pairs(script.Parent:GetDescendants()) do
		if lights:IsA'PointLight' then
			lights.Enabled = not lights.Enabled
		end
	end
end