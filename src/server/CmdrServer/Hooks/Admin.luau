local Admins = {
    game.CreatorId
}

return function(registry)
    registry:RegisterHook("BeforeRun", function(context)
        if context.Group == script.Name and table.find(Admins, context.Executor.UserId) == nil then
            return "Not authorized."
        end

        return
    end)
end
