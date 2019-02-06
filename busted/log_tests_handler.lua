local json = require 'dkjson'

local output = function(options)
    local busted = require("busted")
    local handler = require("busted.outputHandlers." .. options.defaultOutput)(options)

    local suiteEnd = function()
        if options.arguments[1] == nil then
            print("No log file written, because no file name given.")
        else
            local file = io.open (options.arguments[1], "w+")
            if file == nil then error("Could not open file " .. options.arguments[1] .. " for writing log file.") end

            local data = {}

            for _, el in pairs(handler.successes) do
                if el.trace.what == "Lua" then
                    local name = el.name
                    local fileName = el.trace.short_src
                    local fromLine = el.trace.currentline
                    table.insert(data, {
                        name = name,
                        file = fileName,
                        line = fromLine,
                    })
                end
            end

            file:write(json.encode(data))
            print("Log file written to " .. options.arguments[1])
        end

        return nil, true
    end

    busted.subscribe({ 'suite', 'end' }, suiteEnd)

    return handler
end

return output