-- CreatorPanel removed (admin UI replaced by Cmdr)

local CreatorPanel = {}
CreatorPanel.ServiceName = "CreatorPanel"

function CreatorPanel:Init(_serviceBag)
    -- intentionally disabled
end

function CreatorPanel.Start()
    warn("CreatorPanel disabled — admin UI removed")
end

return CreatorPanel
