local flashlightEnabled = script.Parent.f_Enabled

script.Parent.Activated:Connect(function()
	if not flashlightEnabled.Value then
		flashlightEnabled.Value = true
		for i,lights in pairs(script.Parent.LightPart:GetChildren()) do
			if lights:IsA("SpotLight") then 
				lights.Enabled = true 
			end
		end
		script.Parent.Handle.Sound:Play()
	else
		for i,lights in pairs(script.Parent.LightPart:GetChildren()) do 
			if lights:IsA("SpotLight") then
				lights.Enabled = false 
			end
		end
		script.Parent.Handle.Sound:Play()
		flashlightEnabled.Value = false
	end
end)