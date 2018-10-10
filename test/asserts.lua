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

local function logsError(func, expectedLabel)
    if type(func) == "function" then

        local lastError = nil
        local backup = _G.logError
        _G.logError = function(message)
            lastError = message
            backup(message)
        end

        local status, errorMsg = pcall(func)
        _G.logError = backup

        if not status then
            error(errorMsg)
        end
        if expectedLabel ~= nil then
            assert.is_same(expectedLabel, lastError, "expect logged error to be \"" .. expectedLabel .. "\"")
            return true
        else
            return lastError ~= nil
        end
    end
    return false
end

local function logs_error_for_luassert(state, arguments)
    return logsError(arguments[1], arguments[2])
end

s:set("assertion.logsError.positive", "Expected function call to log an error")
s:set("assertion.logsError.negative", "Expected function call to NOT log an error")
assert:register("assertion", "logs_error", logs_error_for_luassert, "assertion.logsError.positive", "assertion.logsError.negative")

local function logsWarning(func, expectedLabel)
    if type(func) == "function" then

        local lastWarning = nil
        local backup = _G.logWarning
        _G.logWarning = function(message)
            lastWarning = message
            backup(message)
        end

        local status, errorMsg = pcall(func)
        _G.logWarning = backup

        if not status then
            error(errorMsg)
        end
        if expectedLabel ~= nil then
            assert.is_same(expectedLabel, lastWarning, "expect logged warning to be \"" .. expectedLabel .. "\"")
            return true
        else
            return false
        end
    end
    return false
end

local function logs_warning_for_luassert(state, arguments)
    return logsWarning(arguments[1], arguments[2])
end

s:set("assertion.logsWarning.positive", "Expected function call to log a warning")
s:set("assertion.logsWarning.negative", "Expected function call to NOT log a warning")
assert:register("assertion", "logs_warning", logs_warning_for_luassert, "assertion.logsWarning.positive", "assertion.logsWarning.negative")