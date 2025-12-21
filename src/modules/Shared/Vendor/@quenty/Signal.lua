local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({ _connections = {} }, Signal)
    return self
end

function Signal:Connect(fn)
    if type(fn) ~= "function" then return end
    local conn = { fn = fn }
    table.insert(self._connections, conn)
    local disconnected = false
    return {
        Disconnect = function()
            if disconnected then return end
            disconnected = true
            for i, c in ipairs(self._connections) do
                if c == conn then
                    table.remove(self._connections, i)
                    break
                end
            end
        end,
    }
end

function Signal:Fire(...)
    for _, c in ipairs(self._connections) do
        pcall(c.fn, ...)
    end
end

function Signal:Destroy()
    self._connections = {}
    setmetatable(self, nil)
end

return Signal
