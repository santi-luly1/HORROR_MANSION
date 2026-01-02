--!strict
local Services = game:GetService("ServerScriptService").Server

local PlayerDataHandler = require(Services.PlayerDataHandler)

return function (context, player: Player, stat: PlayerDataHandler.ValidStats, ammount: number)
    local ok, log = PlayerDataHandler:SetPlayerStat(player, stat, ammount)

    if ok then
        local msg = "Updated."

        context:SendEvent(context.Executor, "Message", msg)
        return msg
    else
        context:Error(log)
        return log :: string
    end
end
