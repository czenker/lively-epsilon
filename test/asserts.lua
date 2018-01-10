local s = require("say")
local assert = require("luassert")

local function containsValue(value, container)
    if type(container) == 'table' then
        for _,v in pairs(container) do
            if v == value then return true end
        end
    end
    return false
end

local function containsValue_for_luassert(state, arguments)
    return containsValue(arguments[1], arguments[2])
end

s:set("assertion.containsValue.positive", "Expected %s\n to be contained in %s")
s:set("assertion.containsValue.negative", "Expected %s\n to NOT be contained in %s")

assert:register("assertion", "contains_value", containsValue_for_luassert, "assertion.containsValue.positive", "assertion.containsValue.negative")