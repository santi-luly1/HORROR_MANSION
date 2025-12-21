local RunService = game:GetService("RunService")

if RunService:IsClient() then
    error("GameFunctions is server-only. Clients must use RemoteEvents or lightweight shared APIs.")
end

return require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("GameFunctions"))
