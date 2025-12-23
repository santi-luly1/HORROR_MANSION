local OpenCoinsShop = {}
OpenCoinsShop.ServiceName = "OpenCoinsShop"

function OpenCoinsShop.Toggle(button)
    if not button or not button.Parent then
        return
    end
    local menus = button.Parent.Parent.Parent.Parent:FindFirstChild("MenusUI")
    if menus and menus:FindFirstChild("CoinsUI") then
        local coinsUI = menus.CoinsUI
        coinsUI.Enabled = not coinsUI.Enabled
    end
end

function OpenCoinsShop.Start(button)
    button.MouseButton1Click:Connect(function()
        OpenCoinsShop.Toggle(button)
    end)
end

return OpenCoinsShop
