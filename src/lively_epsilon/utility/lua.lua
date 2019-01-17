function isString(thing) return type(thing) == "string" end
function isNumber(thing) return type(thing) == "number" end
function isFunction(thing) return type(thing) == "function" end
function isBoolean(thing) return type(thing) == "boolean" end
function isTable(thing) return type(thing) == "table" end
function isNil(thing) return type(thing) == "nil" end

-- try to call a user callback. If it causes an error, print it, but don't propagate it further
function userCallback(func, ...)
    if isFunction(func) then
        local args = {...}
        local result = table.pack(pcall(func, table.unpack(args)))
        local success = table.remove(result, 1)
        if not success then
            local error = table.remove(result, 1)
            local msg = "An error occured when calling a user function"
            if type(error) == "string" then
                msg = msg .. ": " .. error
            end
            logError(msg)
            return nil
        else
            return table.unpack(result)
        end
    else
        if not isNil(func) then
            logError("Expected a function as callback, but got " .. type(func))
        end
        return nil
    end
end