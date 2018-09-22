EventHandler = {
    new = function()
        local events = {}
        return {
            register = function(self, eventName, handler)
                if not isString(eventName) then error("Expected eventName to be a string, but got " .. type(eventName), 2) end
                if not isFunction(handler) then error("Expected handler to be a function, but got " .. type(handler), 2) end
                events[eventName] = events[eventName] or {}
                table.insert(events[eventName], handler)
            end,
            fire = function(self, eventName)
                if not isString(eventName) then error("Expected eventName to be a string, but got " .. type(eventName), 2) end
                for _, handler in pairs(events[eventName] or {}) do
                    handler()
                end
            end
        }
    end
}