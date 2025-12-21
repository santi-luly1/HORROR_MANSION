local DeathNoises = {}
DeathNoises.ServiceName = "DeathNoises"

function DeathNoises:Init(serviceBag)
    assert(not self._serviceBag, "Already initialized")
    self._serviceBag = assert(serviceBag, "No serviceBag provided")
    self._players = game:GetService("Players")
    self._script = script
end

local function playRandomSound(scriptRef)
    local tracks = {}
    for _, child in ipairs(scriptRef:GetChildren()) do
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

local function onCharacter(scriptRef, character)
    local hum = character:FindFirstChild("Humanoid")
    if hum then
        hum.Died:Connect(function()
            playRandomSound(scriptRef)
        end)
    end
end

function DeathNoises:Start()
    self._players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            onCharacter(self._script, character)
        end)
    end)
end

return DeathNoises
