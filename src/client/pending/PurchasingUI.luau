local PurchasingUI = {}
PurchasingUI.ServiceName = "PurchasingUI"

local MarketplaceService
local ReplicatedStorage
local Players

function PurchasingUI:Init(serviceBag)
    self._serviceBag = serviceBag
    MarketplaceService = game:GetService("MarketplaceService")
    ReplicatedStorage = game:GetService("ReplicatedStorage")
    Players = game:GetService("Players")
end

function PurchasingUI.Start(frame)
    if not frame then
        return
    end

    local player = Players.LocalPlayer
    for _, gui in ipairs(frame:GetChildren()) do
        if gui:IsA("Frame") and gui:FindFirstChild("Purchase") then
            local purchaseBtn = gui.Purchase
            purchaseBtn.MouseButton1Click:Connect(function()
                local productIdValue = frame.Parent.ProductsID and frame.Parent.ProductsID:FindFirstChild(gui.Name)
                local productId = productIdValue and productIdValue.Value
                if not productId then
                    return
                end

                MarketplaceService:PromptProductPurchase(player, productId)

                -- Listen for finished once per prompt
                local conn
                conn = MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, returnedProductId, purchased)
                    if returnedProductId ~= productId then
                        return
                    end
                    conn:Disconnect()
                    if purchased then
                        frame:FindFirstChild("Money"):Play()
                        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GiveCoins"):FireServer(gui.ToGive.Value)
                    end
                end)
            end)
        end
    end
end

return PurchasingUI
