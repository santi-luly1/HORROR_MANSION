local ChatMessages = {}
ChatMessages.ServiceName = "ChatMessages"

local StarterGui
local ReplicatedStorage

function ChatMessages:Init(serviceBag)
	self._serviceBag = serviceBag
	StarterGui = game:GetService("StarterGui")
	ReplicatedStorage = game:GetService("ReplicatedStorage")
end

function ChatMessages.Start()
	ReplicatedStorage:WaitForChild("RemoteEvents").SendChatMessages.OnClientEvent:Connect(function(killerName)
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = killerName .. " Arrived!",
			Color = Color3.fromRGB(255, 52, 17),
			Font = Enum.Font.Code,
			TextSize = 20,
		})
	end)
end

return ChatMessages
