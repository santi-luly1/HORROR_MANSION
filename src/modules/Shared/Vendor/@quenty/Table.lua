local Table = {}

function Table.ShallowCopy(t)
    return table.clone(t)
end

function Table.Find(t, fn)
    for k, v in pairs(t) do
        if fn(v, k) then
            return v, k
        end
    end
    return nil
end

function Table.Length(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

return Table
