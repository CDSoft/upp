--[[ pretty(x)
-- convert x to a string.
-- If x is a table, each field is recursively converted.
-- The main purpose of this function is to debug Lua values in a document.
--]]

local function _pretty(t, indent)
    if type(t) == "table" then
        local keys = {}
        for k, _ in pairs(t) do table.insert(keys, k) end
        table.sort(keys)
        local s = "{"
        indent = indent or ""
        local indent2 = indent.."  "
        for _, k in ipairs(keys) do
            s = s.."\n"..indent2..k.." = ".._pretty(t[k], indent2)
        end
        if #keys > 0 then s = s.."\n"..indent.."}" else s = s.."}" end
        return s
    else
        return t
    end
end

local function pretty(x)
    return setmetatable(x, {__tostring = _pretty})
end

return pretty
