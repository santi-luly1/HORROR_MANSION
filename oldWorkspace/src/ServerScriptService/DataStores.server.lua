if script.Parent ~= game.ServerScriptService then
	script.Parent = game.ServerScriptService
end

--Configuration
local Name = "Survivals"
local Name2 = "Coins"
local Type = "IntValue"
local Type2 = "IntValue"
local Value = 0

local KickFail = true --false to disable kicking player if there is an error.
local succesMessageFromDS = "Data."
local errorMessageFromDS = "Error while loading player data values: "
local failKickMessage = "\n Kicked by the server. \n An error ocurred while loading your data and this is to prevent data loss. \n \n Error msg: \n \n"

--Data store services
local ds = game:GetService("DataStoreService")

local Survivals = ds:GetDataStore("Survivals")
local Coins = ds:GetDataStore("Coins")

--Functions
game.Players.PlayerAdded:Connect(function(plr)
	local leaderFolder = Instance.new("Folder", plr)
	leaderFolder.Name = "leaderstats"

	local Main = Instance.new(Type, leaderFolder)
	Main.Name = Name
	
	local Main2 = Instance.new(Type2, leaderFolder)
	Main2.Name = Name2
	
	if Main:IsA("IntValue") or Main:IsA("NumberValue") then
		Main.Value = Value
	end
	
	local SurvivalData
	local CoinData
	
	--Saving data
	local succ, errorMessage = pcall(function()
		SurvivalData = Survivals:GetAsync(plr.UserId)
		CoinData = Coins:GetAsync(plr.UserId)
	end)
	
	if succ and CoinData and SurvivalData then
		warn(succesMessageFromDS)
		plr.leaderstats[Name].Value = SurvivalData
		plr.leaderstats[Name2].Value = CoinData
	else
		if KickFail then
			plr:Kick(failKickMessage, errorMessage)
		end
		
		error(errorMessageFromDS..errorMessage)
	end
end)

game.Players.PlayerRemoving:Connect(function(plr)
	local succ, errorMessage = pcall(function()
		Survivals:SetAsync(plr.UserId, plr.leaderstats[Name].Value)
		Coins:SetAsync(plr.UserId, plr.leaderstats[Name2].Value)
	end)
	
	if succ then
		warn(succesMessageFromDS)
	else
		error(errorMessageFromDS..errorMessage)
	end
end)

game:BindToClose(function()
	wait(1.5)
	print("Closing.")
end)