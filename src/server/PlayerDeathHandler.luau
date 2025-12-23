local PlayerDeathHandler = {}
PlayerDeathHandler.ServiceName = "PlayerDeathHandler"

--------------------------------------------------------------------
--- Internal
--------------------------------------------------------------------
local function playRandomSound()
    local tracks = {}
    for _, child in ipairs(script:GetChildren()) do
        if child:IsA("Sound") then
            table.insert(tracks, child)
        end
    end
    if #tracks == 0 then
        return
    end

    local rn = math.random(1, #tracks)
    local track = tracks[rn]
    if track then
        track:Play()
        task.wait(track.TimeLength)
        track:Pause()
    end
end

function PlayerDeathHandler:_onCharacter(character)
    local hum = character:WaitForChild("Humanoid", 30) -- will this yield the entire server death sound? Hmmm
    if hum then
        hum.Died:Connect(function()
            warn(`[PlayerDeathHandler] Player {character.Name} has died.`)
            self._players:GetPlayerFromCharacter(character):SetAttribute("PlayerState", "Dead")
            playRandomSound()
        end)
    end
end

--------------------------------------------------------------------
--- ServiceBag
--------------------------------------------------------------------
function PlayerDeathHandler:Init(serviceBag)
    assert(not self._serviceBag, "Already initialized")
    self._serviceBag = assert(serviceBag, "No serviceBag provided")
    self._players = game:GetService("Players")
end

function PlayerDeathHandler:Start()
    self._players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:_onCharacter(character)
        end)
    end)
end

return PlayerDeathHandler
