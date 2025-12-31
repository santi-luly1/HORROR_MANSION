-- a bit useless, don't you think?
local ClientBootstrapService = {}
ClientBootstrapService.ServiceName = "ClientBootstrapService"

local require = (require :: any)(script.Parent.loader).load(script)

function ClientBootstrapService:Init(serviceBag)
    self._serviceBag = serviceBag
end

function ClientBootstrapService:Start()
    -- start UI and shared client modules (use module loader)
    local clientInit
    do
        local ok, m = pcall(function()
            return require("ClientInit")
        end)
        if ok then
            clientInit = m
        end
    end
    if clientInit and type(clientInit.Start) == "function" then
        pcall(clientInit.Start, self._serviceBag)
    end

    -- per-character behaviors
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    if not player then
        return
    end

    local function onCharacter(character)
        pcall(function()
            local ok, PlayerAssign = pcall(function()
                return require("PlayerAssign")
            end)
            if ok and PlayerAssign and type(PlayerAssign.OnCharacter) == "function" then
                PlayerAssign.OnCharacter(character)
            end
        end)
        pcall(function()
            local ok, PlayerVisuals = pcall(function()
                return require("PlayerVisuals")
            end)
            if ok and PlayerVisuals and type(PlayerVisuals.OnCharacter) == "function" then
                PlayerVisuals.OnCharacter(character)
            end
        end)
        pcall(function()
            local ok, RFP = pcall(function()
                return require("RFP")
            end)
            if ok and RFP and type(RFP.OnCharacter) == "function" then
                RFP.OnCharacter(character)
            end
        end)
    end

    player.CharacterAdded:Connect(onCharacter)
    if player.Character then
        onCharacter(player.Character)
    end

    -- start chat messages
    pcall(function()
        local ok, ChatMessages = pcall(function()
            return require("ChatMessages")
        end)
        if ok and ChatMessages and type(ChatMessages.Start) == "function" then
            ChatMessages.Start()
        end
    end)
end

return ClientBootstrapService
