EventHandler = {
    new = function(self, config)
        config = config or {}
        if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
        local failIfEventNameNotAllowed = function(eventName)
            if not isString(eventName) then error("Expected eventName to be a string, but got " .. type(eventName), 4) end
        end
        if config.allowedEvents ~= nil then
            local allowedEvents = {}
            if not isTable(config.allowedEvents) then error("Expected config.allowedEvents to be a table, but got " .. type(config.allowedEvents), 3) end
            for _, value in pairs(config.allowedEvents) do
                if not isString(value) then error("Expected all values in config.allowedEvents to be strings, but got " .. type(value), 4) end

                allowedEvents[value] = value
            end

            failIfEventNameNotAllowed = function(eventName)
                if not isString(eventName) then error("Expected eventName to be a string, but got " .. type(eventName), 4) end

                if allowedEvents[eventName] == nil then error("The eventName " .. eventName .. " is not valid. Most likely you misstyped the eventName.", 4) end
            end
        end

        local events = {}
        return {
            register = function(self, eventName, handler)
                failIfEventNameNotAllowed(eventName)
                if not isFunction(handler) then error("Expected handler to be a function, but got " .. type(handler), 2) end
                events[eventName] = events[eventName] or {}
                table.insert(events[eventName], handler)
            end,
            fire = function(self, eventName)
                failIfEventNameNotAllowed(eventName)
                if not isString(eventName) then error("Expected eventName to be a string, but got " .. type(eventName), 2) end
                for _, handler in pairs(events[eventName] or {}) do
                    handler()
                end
            end
        }
    end
}