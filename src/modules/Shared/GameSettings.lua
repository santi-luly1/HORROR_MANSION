local RunService = game:GetService("RunService")

if RunService:IsClient() then
    error("GameSettings is server-only. Clients should not require this module.")
end

return require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("GameSettings"))
