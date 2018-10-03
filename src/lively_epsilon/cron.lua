local now = 0.0
local events = {}

-- Cron is a component to handle code that is to be executed after a certain time
--
-- Its main goal is to reduce load during scripting. Not every condition has to be
-- checked on every tick. The enemies attacking your crew only half a second after
-- you got closer then 30u to them is not a difference the crew would notice, but
-- it reduces load on the server.
--
-- A nice side effect is also that it makes working with delays and timeouts very easy.

Cron = {
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
                local status, error = pcall(value.func, key)
                if not status then
                    msg = "An error occured in Cron with " .. key
                    if type(error) == "string" then
                        msg = msg .. ": " .. error
                    end
                    logError(msg)
                elseif isNumber(error) then
                    cronOverride = error
                end

                if value.cron ~= nil then
                    value.next = value.next + (cronOverride or value.cron)
                end
            end
        end
    end,

    -- Example:
    --
    --   Cron.once("identifier", function() print("Hello World") end, 10)
    once = function(name, func, delay)
        if type(name) == "function" then
            delay = func
            func = name
            name = Util.randomUuid()
        end

        events[name] = {
            next = now + (delay or 0),
            func = func,
            cron = nil
        }

        return name
    end,

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
            cron = interval or 60
        }

        return name
    end,
    abort = function(name)
        events[name] = nil
    end,
    getDelay = function(name)
        if events[name] == nil then
            return nil
        else
            return events[name].next - now
        end
    end,
    setDelay = function(name, delay)
        if events[name] ~= nil then
            events[name].next = now + delay
        end
    end,
    addDelay = function(name, delay)
        if events[name] ~= nil then
            events[name].next = events[name].next + delay
        end
    end,
    now = function()
        return now
    end,
}