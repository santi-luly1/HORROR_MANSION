--[=[
    Server death manager for players
	@class PlayerDeathHandler
    @author: santi-luly1

    CHANGELOG: [
		12/31/25 --> Adapted from original source.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")

local PlayerDeathHandler = {
	_init = false,
	_start = false,
}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local tracks = script:GetChildren()

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------

--------------------------------------------------------------------
--- ServiceBag (not currently using service bag)
--------------------------------------------------------------------
function PlayerDeathHandler:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
	self._init = true
end

function PlayerDeathHandler:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
	self._start = true

	math.randomseed(tick()) -- just bc

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character) -- memory leak?
			local hum = character:WaitForChild("Humanoid", 30) -- will this yield for the entire server? Hmmm
			if hum then
				hum.Died:Once(function()
					warn(`[{script.Name}] Player {character.Name} has died.`)
					player:SetAttribute("PlayerState", "Dead")
					local track = tracks[math.random(1, #tracks)]:Clone()
					track.Parent = character.PrimaryPart
                    track:Play()
				end)
			end
		end)
	end)
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------

return PlayerDeathHandler
