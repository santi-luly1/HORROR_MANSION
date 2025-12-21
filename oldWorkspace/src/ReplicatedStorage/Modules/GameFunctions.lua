local Settings = require(script.Parent.GameSettings)
local functionsTable = {}

local SavedPlayersFolder = game.ReplicatedStorage.SavedPlayers
local Timer = Settings.Main.GameTimer
local TheKillerValue = Settings.Main.Killer
local Map = Settings.Main.Map

-- // ServerScriptService.GameLogic.Adding
function functionsTable.DataCreator(plr)
	local plrValue = Instance.new("IntValue", SavedPlayersFolder.NeutralPlayers)
	plrValue.Name = plr.Name
	plrValue.Value = plr.UserId
	
	local ActualDate = os.date("*t")
	local Months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
	local Date
	local DayTime = ActualDate.hour..":"..ActualDate.min..":"..ActualDate.sec

	for i, Month in pairs(Months) do
		if ActualDate.month == i then
			Date = Month.."/"..ActualDate.day.."/"..ActualDate.year
		end
	end

	warn("["..Date.." --- "..DayTime.."]".."[PLAYER JOINED] Created "..plr.Name.." values in "..SavedPlayersFolder.NeutralPlayers.Name.." folder.")
end
function functionsTable.DataDestroyer(plr)
	for _, findPlayer in pairs(SavedPlayersFolder:GetDescendants()) do
		if not findPlayer:IsA'Folder' and findPlayer.Name == plr.Name and findPlayer.Value == plr.UserId then
			findPlayer:Destroy()
		end
	end
end
-- // ServerScriptService.GameLogic.Adding

-- // ServerScriptService.GameLogic
function functionsTable.chooseRandomSpawn(killer)
	local Spawns = Map.Map.Spawns.Killers:GetChildren()
	local Selected = math.random(1, #Spawns)

	local tp_CFrame = Spawns[Selected].CFrame

	local TeleportPart = killer:FindFirstChild("HumanoidRootPart")

	if TeleportPart == nil then
		TeleportPart = killer:FindFirstChild("Torso")
		if TeleportPart == nil then
			TeleportPart = killer:FindFirstChild("UpperTorso")
			if TeleportPart == nil then
				TeleportPart = killer:FindFirstChild("Head")
			end
		end
	end

	TeleportPart.CFrame = tp_CFrame
end

function functionsTable.chooseRandomKiller()
	local Killers = game.ServerStorage.Killers:GetChildren()
	local Selected = math.random(1, #Killers)
	local Killer = Killers[Selected]

	Killer:Clone().Parent = workspace.Killer
	Settings.Main.Killer = Killer

	functionsTable.chooseRandomSpawn(Killer)

	return Killer
end

function functionsTable.startGame()
	TheKillerValue = functionsTable.chooseRandomKiller()
	local MainMessage = Instance.new("Message", workspace.MessagesHints)
	MainMessage.Name = "MainMessage__KillerArrivedMessage"
	MainMessage.Text = TheKillerValue.Name.." is here!!"
	
	wait(Settings.Main["ServerScriptService.GameLogic"].waitTimes)

	for _, plrs in pairs(SavedPlayersFolder:GetDescendants()) do
		if plrs:IsA'IntValue' then
			plrs.Parent = SavedPlayersFolder.SurvivedPlayers
		end
	end

	game.ReplicatedStorage.RemoteEvents.SendChatMessages:FireAllClients(TheKillerValue.Name)

	MainMessage:Destroy()
	
	if Settings.Main.GameTimer.Base ~= 0 then
		Settings.Main.GameTimer.Countdown = Settings.Main.GameTimer.Base
	else
		Settings.Main.GameTimer.Countdown = Settings.Main.GameTimer.Default
	end
	
	functionsTable.chooseRandomKiller()
	
	if #workspace.Killer:GetChildren() > 1 then
		for _, killer in pairs(workspace.Killer:GetChildren()) do
			if killer ~= TheKillerValue and not killer:IsA'Script' then
				local s, errorMessage = pcall(function()
					killer:Destroy()
				end)

				if not s then
					warn("Failed destroying the killer clone: ", errorMessage, ". Trying to :Remove()")

					local success, errorMessage2 = pcall(function()
						killer:Remove()
					end)

					if not s then
						TheKillerValue = nil
						Settings.Main.GameTimer.Countdown = Settings.Main.GameTimer["In-game_error"]
						for _, movePlayers in pairs(SavedPlayersFolder:GetDescendants()) do
							if movePlayers:IsA'IntValue' then
								movePlayers.Parent = SavedPlayersFolder.NeutralPlayers
							end
						end
						warn("Failed destroying and removing the killer clone: ", errorMessage2)
					end
				end
			end
		end
	end

	if not workspace.MessagesHints:FindFirstChild("Timer") then
		local InGameTimer = Instance.new("Hint", workspace.MessagesHints)
		InGameTimer.Name = "Timer"
		InGameTimer.Text = "If youre seeing this, probably the game is bugged, so rejoin ;D"
	end
end

function functionsTable.ShowSurvivors(SurvivorsTable, messageInstance)
	
end

function functionsTable.endGame()
	if workspace.Killer:FindFirstChild("MainKillerFunctions") then workspace.Killer.MainKillerFunctions.Parent = workspace end
	repeat wait() workspace.Killer:ClearAllChildren() warn("Clearing all Killers in folder") until #workspace.Killer:GetChildren() == 0
	if workspace:FindFirstChild("MainKillerFunctions") then workspace.MainKillerFunctions.Parent = workspace.Killer end
	if not workspace.Killer:FindFirstChild("MainKillerFunctions") then
		local newScript = Instance.new("Script", workspace.Killer)
		newScript.Name = "MainKillerFunctions"
		newScript.Source = workspace.MainKillerFunctions_Copy.Source
	end
	
	local MainMessage = Instance.new("Message", workspace.MessagesHints)
	MainMessage.Name = "KillerLeavedMessage"

	if TheKillerValue ~= nil then
		MainMessage.Text = TheKillerValue.Name.." has gone!"
	end

	-- //Rewards
	local RandomCoinsReward = math.random(25, 100)

	for _, players in pairs(game.Players:GetPlayers()) do
		if SavedPlayersFolder.SurvivedPlayers:FindFirstChild(players.Name) then
			players.leaderstats.Survivals.Value+= 1
			players.leaderstats.Coins.Value += RandomCoinsReward
		elseif SavedPlayersFolder.DiedPlayers:FindFirstChild(players.Name) then
			players.leaderstats.Coins.Value += (RandomCoinsReward / 2)
		end
	end
	warn("Total coins to all players:", RandomCoinsReward, " ", (RandomCoinsReward / 2))
	wait(Settings.Main["ServerScriptService.GameLogic"].waitTimes)

	MainMessage.Name = "Survivors"

	if #SavedPlayersFolder.SurvivedPlayers:GetChildren() == #game.Players:GetChildren() then
		MainMessage.Text = "All players have survived!"
	elseif #SavedPlayersFolder.SurvivedPlayers:GetChildren() == 0 then
		MainMessage.Text = "Nobody survived!"
	elseif #SavedPlayersFolder.SurvivedPlayers:GetChildren() ~= #game.Players:GetChildren() then
		--functionsTable.ShowSurvivors(SavedPlayersFolder.SurvivedPlayers:GetChildren(), MainMessage)
		for _, plrs in pairs(game.Players:GetPlayers()) do
			plrs.PlayerGui:WaitForChild("SurvivedPlrsList", 120).Enabled = true
		end
	end

	wait(Settings.Main["ServerScriptService.GameLogic"].waitTimes)

	MainMessage:Destroy()

	if workspace:FindFirstChild("MainKillerFunctions") then
		workspace.MainKillerFunctions.Parent = workspace.Killer
	end

	for _, plrs in pairs(game.Players:GetPlayers()) do
		plrs.PlayerGui:WaitForChild("SurvivedPlrsList", 120).Enabled = false
	end

	if not workspace.MessagesHints:FindFirstChild("EndedWaitCountdown") then
		local MainCountdown = Instance.new("Hint", workspace.MessagesHints)
		MainCountdown.Name = "EndedWaitCountdown"

		if workspace.MessagesHints:FindFirstChild("Timer") then
			workspace.MessagesHints:WaitForChild("Timer"):Destroy()
		end

		for _, plrs in pairs(SavedPlayersFolder:GetDescendants()) do
			if plrs:IsA'IntValue' then
				plrs.Parent = SavedPlayersFolder.NeutralPlayers
			end
		end

		if Settings.Main["ServerScriptService.GameLogic"].showChangeMap then
			for _, showVotingUI in pairs(game.Players:GetPlayers()) do
				showVotingUI.PlayerGui.MenusUI.VotingMapUI.Enabled = true
				Settings.Main["ServerScriptService.GameLogic"].DoStartGame = false
			end
		end

		for Countdown = Settings.Main["ServerScriptService.GameLogic"].IntermissionTime, 0, -1 do
			MainCountdown.Text = "The next killer will spawn in "..Countdown.." seconds."
			wait(1)
		end

		MainCountdown:Destroy()

		for _, showVotingUI in pairs(game.Players:GetPlayers()) do
			showVotingUI.PlayerGui.MenusUI.VotingMapUI.Enabled = false
		end
	end

	if Settings.Main["ServerScriptService.GameLogic"].DoStartGame then
		if Settings.Main["ServerScriptService.GameLogic"].Voting.TotalStartedMatchs >= Settings.Main["ServerScriptService.GameLogic"].Voting.Min then
			Settings.Main["ServerScriptService.GameLogic"].showChangeMap = true
			Settings.Main["ServerScriptService.GameLogic"].Voting.TotalStartedMatchs = 0
		else
			Settings.Main["ServerScriptService.GameLogic"].showChangeMap = false
		end

		Settings.Main["ServerScriptService.GameLogic"].Voting.TotalStartedMatchs += 1
		functionsTable.startGame()
	else
		Settings.Main["ServerScriptService.GameLogic"].showChangeMap = false
		Settings.Main["ServerScriptService.GameLogic"].DoStartGame = true
		functionsTable.endGame()
	end
end
-- // ServerScriptService.GameLogic

return functionsTable