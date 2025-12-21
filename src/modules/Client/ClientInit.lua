local ClientInit = {}
ClientInit.ServiceName = "ClientInit"

function ClientInit:Init(serviceBag)
    self._serviceBag = serviceBag
end

function ClientInit.Start(serviceBag)
    local _serviceBag = serviceBag or ClientInit._serviceBag
    local Players = game:GetService("Players")

    local player = Players.LocalPlayer
    if not player then
        return
    end

    local StarterGui = game:GetService("StarterGui")

    -- helper finders
    local playerGui = player:WaitForChild("PlayerGui")

    local function findFrameWithChildren(root, keys)
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("GuiObject") or inst:IsA("Frame") or inst:IsA("ScreenGui") then
                local okAll = true
                for _, k in ipairs(keys) do
                    if not inst:FindFirstChild(k) then
                        okAll = false
                        break
                    end
                end
                if okAll then
                    return inst
                end
            end
        end
        return nil
    end

    --[[ UpdateUI
    do
        local mod = safeRequire("UpdateUI")
        if mod and type(mod.Start) == "function" then
            local frame = playerGui:FindFirstChild("UI") or StarterGui:FindFirstChild("UI")
            if frame then
                frame = frame:FindFirstChild("Update") or findFrameWithChildren(frame, {"Survivals", "Coins"})
            else
                frame = findFrameWithChildren(playerGui, {"Survivals", "Coins"})
            end
            if frame then
                pcall(mod.Start, frame)
            end
        end
    end

    -- SurvivedList
    do
        local mod = safeRequire("SurvivedList")
        if mod and type(mod.Start) == "function" then
            local sg = playerGui:FindFirstChild("SurvivedPlrsList")
            if sg then
                local content = sg:FindFirstChild("Content")
                local template = sg:FindFirstChild("PlayerFrame")
                if content and template then
                    pcall(mod.Start, content, template)
                end
            end
        end
    end

    -- VotingMapUI
    do
        local mod = safeRequire("VotingMapUI")
        if mod and type(mod.Start) == "function" then
            local menus = playerGui:FindFirstChild("MenusUI") or StarterGui:FindFirstChild("MenusUI")
            if menus then
                local voting = menus:FindFirstChild("VotingMapUI")
                if voting then
                    local content = voting:FindFirstChild("content")
                    if content then
                        pcall(mod.Start, content)
                    end
                end
            end
        end
    end

    -- Purchasing UI
    do
        local mod = safeRequire("PurchasingUI")
        if mod and type(mod.Start) == "function" then
            local menus = playerGui:FindFirstChild("MenusUI") or StarterGui:FindFirstChild("MenusUI")
            if menus and menus:FindFirstChild("CoinsUI") then
                local main = menus.CoinsUI:FindFirstChild("Main")
                if main then
                    local products = main:FindFirstChild("ProductsContent") or main:FindFirstChild("Products")
                    if products then
                        pcall(mod.Start, products)
                    end
                end
            end
        end
    end

    -- OpenCoinsShop button
    do
        local mod = safeRequire("OpenCoinsShop")
        if mod and type(mod.Start) == "function" then
            local uiRoot = playerGui:FindFirstChild("UI") or StarterGui:FindFirstChild("UI")
            if uiRoot then
                for _, btn in ipairs(uiRoot:GetDescendants()) do
                    if btn:IsA("GuiButton") and (btn.Name == "OpenCoinsShop" or btn.Name == "OpenCoins") then
                        pcall(mod.Start, btn)
                    end
                end
            end
        end
    end]]
end

return ClientInit

