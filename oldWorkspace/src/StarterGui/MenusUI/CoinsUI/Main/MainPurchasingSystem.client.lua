local Player = game.Players.LocalPlayer
local MPS = game:GetService("MarketplaceService")

for _, Guis in pairs(script.Parent.ProductsContent:GetChildren()) do
	if Guis:IsA'Frame' then
		Guis.Purchase.MouseButton1Click:Connect(function()
			MPS:PromptProductPurchase(Player, Guis.Parent.Parent.ProductsID:FindFirstChild(Guis.Name).Value)
			MPS.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
				if Guis.Parent.Parent.ProductsID:FindFirstChild(Guis.Name).Value ~= productId then return end
				
				warn("[Purchaasing Coins] Window closed.")
				if purchased then
					script.Money:Play()
					warn("[Purchaasing Coins] Giving ", tonumber(Guis.ToGive.Value), " to ", Player.Name, ".")
					game.ReplicatedStorage.RemoteEvents.GiveCoins:FireServer(Guis.ToGive.Value)
				end
			end)
		end)
	end
end