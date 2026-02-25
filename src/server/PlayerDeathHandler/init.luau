--!strict
--[=[
    Server death manager for players
	@class PlayerDeathHandler
    @author: santi-luly1

    CHANGELOG: [
		12/31/25 --> Adapted from original source.
		01/30/26 --> Indexed all the deaths sounds into a module.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Players = game:GetService("Players")

--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
local PlayerDeathHandler = {
	_init = false,
	_start = false,
}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local SoundsIndex = require(script.Sounds)

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Init / Start
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
		player.CharacterAdded:Connect(function(character: Model) -- memory leak?
			--player:SetAttribute("Dead", false) -- little bug (race conditions)
			local hum = character:WaitForChild("Humanoid", 30) :: Humanoid -- will this yield for the entire server? Hmmm
			if hum then
				hum.Died:Once(function()
					warn(`[{script.Name}] Player {player.Name} has died.`)
					player:SetAttribute("Dead", true)

					--generic sound
					local track = Instance.new("Sound")
					track.SoundId = `rbxassetid://{SoundsIndex[math.random(1, #SoundsIndex)]}`
					track.Parent = character.PrimaryPart
					track.Ended:Once(function()
						track:Destroy() -- would this even be needed? Character is gonna respawn, deleting this in the process anyways
					end)
					track:Play()
				end)
			end
		end)
	end)
end

--------------------------------------------------------------------
--- Private Methods
--------------------------------------------------------------------

--------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------

return PlayerDeathHandler
