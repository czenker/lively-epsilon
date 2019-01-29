local now = 0.0
local events = {}

--- Cron is a component to handle code that is to be executed after a certain time
---
--- Its main goal is to reduce load during scripting. Not every condition has to be
--- checked on every tick. The enemies attacking your crew only half a second after
--- you got closer then 30u to them is not a difference the crew would notice, but
--- it reduces load on the server.
---
--- A nice side effect is also that it makes working with delays and timeouts very easy.
Cron = {
    ---@param delta number of the ellapsed time since the last call
    tick = function(delta)
        now = now + delta

        local i = 1
        local keys = {}
        for key, _ in pairs(events) do
            keys[i] = key
            i = i + 1
        end

        for _, key in pairs(keys) do
            local value = events[key]
            if value ~= nil and value.next <= now then
                if value.cron == nil then events[key] = nil end
                local cronOverride
                local status, error = pcall(value.func, key, now - value.last)
                if not status then
                    local msg = "An error occured in Cron with " .. key
                    if type(error) == "string" then
                        msg = msg .. ": " .. error
                    end
                    logError(msg)
                elseif isNumber(error) then
                    cronOverride = error
                end

                if value.cron ~= nil then
                    value.next = value.next + (cronOverride or value.cron)
                    value.last = now
                end
            end
        end
    end,

    ---Calls a function once after a delay.
    ---
    ---Example:
    ---
    ---  Cron.once("identifier", function() print("Hello World") end, 10)
    ---@param name string unique identifier
    ---@param func function the function to call once
    ---@param delay number the number of seconds after which the function should be called
    once = function(name, func, delay)
        if type(name) == "function" then
            delay = func
            func = name
            name = Util.randomUuid()
        end

        events[name] = {
            next = now + (delay or 0),
            func = func,
            cron = nil,
            last = now,
        }

        return name
    end,

    ---Calls a function regularily at a specific interval.
    ---
    ---@param name string unique identifier
    ---@param func function the function to call once
    ---@param interval number the interval in seconds at which the function should be called
    ---@param delay number the initial delay in seconds after which the function is called for the first time
    regular = function(name, func, interval, delay)
        if isFunction(name) then
            delay = interval
            interval = func
            func = name
            name = Util.randomUuid()
        end
        events[name] = {
            next = now + (delay or 0),
            func = func,
            cron = interval or 0,
            last = now,
        }

        return name
    end,
    --- Abort a Cron
    ---
    ---@param name string unique identifier of the cron to be aborted.
    abort = function(name)
        events[name] = nil
    end,

    --- Get the time in seconds until the cron will be called the next time
    ---
    ---@param name string unique identifier of the cron to be aborted.
    getDelay = function(name)
        if events[name] == nil then
            return nil
        else
            return events[name].next - now
        end
    end,
    ---@obsolete will be removed
    ---@param name string
    ---@param delay number
    setDelay = function(name, delay)
        if events[name] ~= nil then
            events[name].next = now + delay
        end
    end,
    --- postpone the cron by the specified delay in seconds
    ---@param name string unique identifier of the cron
    ---@param delay number seconds to postpone the execution
    addDelay = function(name, delay)
        if events[name] ~= nil then
            events[name].next = events[name].next + delay
        end
    end,
    ---get the current in-game time in seconds
    now = function()
        return now
    end,
}