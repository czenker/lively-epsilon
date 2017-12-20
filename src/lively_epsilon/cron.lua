local now = 0.0
local events = {}

Cron = {
    tick = function(delta)
        now = now + delta

        for key, value in pairs(events) do
            if value.next <= now then
                local status, error = pcall(value.func)
                if not status then
                    if type(error) == "string" then
                        print("An error occured in Cron with " .. key .. ": " .. error)
                    else
                        print("An error occured in Cron with " .. key)
                    end
                end

                -- if an error occurs we log it, but continue
                if value.cron ~= nil and value.cron > 0 then
                    value.next = value.next + value.cron
                else
                    events[key] = nil
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
    end,
    regular = function(name, func, interval, delay)
        events[name] = {
            next = now + (delay or 0),
            func = func,
            cron = interval or 60
        }
    end,
    abort = function(name)
        events[name] = nil
    end
}