--[[ count(name [, initial_value])
-- returns a counter, starting from 1 or initial_value
-- The document can define several counters, identified by their names.
--]]

local counters = {}

function count(counter_name, initial_value)
    counters[counter_name] = initial_value or (counters[counter_name] or 0) + 1
    return counters[counter_name]
end
