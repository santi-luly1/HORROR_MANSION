local Maid = {}
Maid.__index = Maid

function Maid.new()
    local self = setmetatable({ _tasks = {} }, Maid)
    return self
end

function Maid:GiveTask(task)
    if task == nil then return end
    table.insert(self._tasks, task)
    return task
end

function Maid:DoCleaning()
    for _, t in ipairs(self._tasks) do
        local typ = typeof(t)
        if typ == "RBXScriptConnection" then
            pcall(function()
                t:Disconnect()
            end)
        elseif typ == "Instance" then
            pcall(function()
                t:Destroy()
            end)
        elseif type(t) == "function" then
            pcall(t)
        elseif type(t) == "table" and type(t.Destroy) == "function" then
            pcall(function()
                t:Destroy()
            end)
        end
    end
    self._tasks = {}
end

function Maid:Destroy()
    self:DoCleaning()
    setmetatable(self, nil)
end

return Maid
