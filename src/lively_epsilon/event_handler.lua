EventHandler = {
    new = function(self, config)
        config = config or {}
        if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
        local failIfEventNameNotAllowed = function(eventName)
            if not isString(eventName) then error("Expected eventName to be a string, but got " .. typeInspect(eventName), 3) end
        end
        if config.allowedEvents ~= nil then
            local allowedEvents = {}
            if not isTable(config.allowedEvents) then error("Expected config.allowedEvents to be a table, but got " .. typeInspect(config.allowedEvents), 3) end
            for _, value in pairs(config.allowedEvents) do
                if not isString(value) then error("Expected all values in config.allowedEvents to be strings, but got " .. typeInspect(value), 4) end

                allowedEvents[value] = value
            end

            failIfEventNameNotAllowed = function(eventName)
                if not isString(eventName) then error("Expected eventName to be a string, but got " .. typeInspect(eventName), 3) end

                if allowedEvents[eventName] == nil then error("The eventName " .. eventName .. " is not valid. Most likely you misstyped the eventName.", 3) end
            end
        end

        local events = {}

        return {
            register = function(self, eventName, handler, priority)
                failIfEventNameNotAllowed(eventName)
                if not isFunction(handler) then error("Expected handler to be a function, but got " .. typeInspect(handler), 2) end
                priority = priority or 0
                if not isNumber(priority) then error("Expected prioritiy to be a number, but got " .. typeInspect(priority), 2) end

                events[eventName] = events[eventName] or {}
                events[eventName][priority] = events[eventName][priority] or {}
                table.insert(events[eventName][priority], handler)
            end,
            fire = function(self, eventName, arg)
                failIfEventNameNotAllowed(eventName)
                if not isString(eventName) then error("Expected eventName to be a string, but got " .. typeInspect(eventName), 2) end

                logDebug("Event " .. eventName .. " fired")

                if events[eventName] ~= nil then
                    local priorities = {}
                    for priority, _ in pairs(events[eventName]) do
                        table.insert(priorities, priority)
                    end
                    table.sort(priorities)

                    for _, prio in pairs(priorities) do
                        for _, handler in pairs(events[eventName][prio]) do
                            local status, error = pcall(handler, nil, arg)
                            if not status then
                                local msg = "An error occured while executing listeners for " .. eventName
                                if isString(error) then
                                    msg = msg .. ": " .. error
                                end
                                logError(msg)
                            end
                        end
                    end
                end
            end
        }
    end
}