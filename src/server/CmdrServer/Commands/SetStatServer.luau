--!strict
local Services = game:GetService("ServerScriptService").Server

local PlayerDataHandler = require(Services.PlayerDataHandler)

return function (context, player: Player, stat: PlayerDataHandler.ValidStats, ammount: number)
    local ok = PlayerDataHandler:SetPlayerStat(player, stat, ammount)

    if ok then
        local msg = "Updated."

        context:SendEvent(context.Executor, "Message", msg)
        return msg
    else
        local msg = "Could not update."

        context:Error(msg)
        return msg
    end
end
