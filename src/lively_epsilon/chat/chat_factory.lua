Chatter = Chatter or {}

-- this chatter factory is able to generate (parameterized) chats
Chatter.newFactory = function(self, cardinality, factory, config)
    if not isNumber(cardinality) then error("Cardinality needs to be a number, " .. type(cardinality) .. " given.", 2) end
    if cardinality < 1 or math.floor(cardinality) ~= cardinality then error("Cardinality needs to be a positive number, " .. cardinality .. " given.", 2) end
    if not isFunction(factory) then error("Factory needs to be function, but " .. type(factory) .. " given.", 2) end

    config = config or {}
    if not isTable(config) then error("Config needs to be a table, but " .. type(config) .. " given", 2) end
    config.filters = config.filters or {}
    if not Util.isNumericTable(config.filters) then error("config.filters needs to be a table with numeric indices, but " .. type(config.filters) .. " given.", 2) end

    -- expects an array where the parameter to test is the first one. Expects the others have been tested already.
    local validate = function(args)
        local n = Util.size(args)

        if not isEeShipTemplateBased(args[1]) then
            return false
        end
        if config.filters[n] ~= nil then
            if not isFunction(config.filters[n]) then error("Expected config.filter to be a function at position " .. n .. ", but got " .. type(config.filters[n])) end

            -- @TODO: error handling
            local ret = config.filters[n](table.unpack(args))
            if not isBoolean(ret) then logWarning("Expected filter to return a boolean at position " .. n .. ", but got " .. type(ret) .. ". Assuming true.") end
            if not ret then return false end
        end
        return true
    end

    return {
        getCardinality = function() return cardinality end,
        areValidArguments = function(self, ...)
            local args = {...}
            local n = Util.size(args)
            if n < 1 then error("Expected function to be called with at least one argument. None given.", 2) end
            if n > cardinality then error("More arguments given than cardinality. Expected " .. cardinality .. ", but got " .. n .. ".", 2) end

            local tempTable = {}
            for i=1,n do
                table.insert(tempTable, 1, args[i])
                if validate(tempTable) == false then return false end
            end
            return true
        end,
        createChat = function(self, ...)
            -- @TODO: error handling
            return factory(table.unpack({...}))
        end,
    }
end

Chatter.isChatFactory = function(self, thing)
    return isTable(thing) and
            isFunction(thing.getCardinality) and
            isFunction(thing.areValidArguments) and
            isFunction(thing.createChat)
end
