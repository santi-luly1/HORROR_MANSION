local VotingMapUI = {}
VotingMapUI.ServiceName = "VotingMapUI"

local ReplicatedStorage
local UserInputService
local RemoteEvents

function VotingMapUI:Init(serviceBag)
	self._serviceBag = serviceBag
	ReplicatedStorage = game:GetService("ReplicatedStorage")
	UserInputService = game:GetService("UserInputService")
	RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
end

function VotingMapUI.Start(content)
	-- Input keyboard handler
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		RemoteEvents.KeyPressed:FireServer(input.KeyCode, gameProcessed)
	end)

	-- Mobile buttons
	local yes = content:FindFirstChild("Yes")
	local no = content:FindFirstChild("No")
	if yes and yes:IsA("GuiButton") then
		yes.MouseButton1Click:Connect(function()
			RemoteEvents.KeyPressed:FireServer(Enum.KeyCode.Q, false)
		end)
	end
	if no and no:IsA("GuiButton") then
		no.MouseButton1Click:Connect(function()
			RemoteEvents.KeyPressed:FireServer(Enum.KeyCode.E, false)
		end)
	end

	-- Color change remote
	RemoteEvents.KeyPressed.ChangeVotingColor.OnClientEvent:Connect(function(greenObj, neutralObj)
		if greenObj and greenObj:IsA("TextLabel") then
			greenObj.TextColor3 = Color3.fromRGB(0, 255, 0)
		end
		if neutralObj and neutralObj:IsA("TextLabel") then
			neutralObj.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
end

return VotingMapUI
