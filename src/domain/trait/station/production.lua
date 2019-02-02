Station = Station or {}
--- a station that produces or consumes products
--- @param self
--- @param station SpaceStation
--- @param configuration table
--- @return SpaceStation
Station.withProduction = function (self, station, configuration)
    if not isEeStation(station) then
        error ("Expected a station but got " .. typeInspect(station), 2)
    end
    if not Station:hasStorage(station) then
        error ("station " .. station:getCallSign() .. " needs to have a storage configured", 2)
    end

    if Station:hasProduction(station) then
        -- @TODO: ???
        error("can not reconfigure production", 2)
    end

    if type(configuration) ~= "table" then
        error("Expected a table with configuration, but got " .. typeInspect(configuration), 2)
    end

    local produces = {}
    local consumes = {}

    for _, conf in pairs(configuration) do
        local uuid = Util.randomUuid()
        local cronId = station:getCallSign() .. "_production_" .. uuid

        mergeTables(conf, {
            productionTime = 10,
            consumes = {},
            produces = {},
        })
        if Util.size(conf.consumes) == 0 and Util.size(conf.produces) == 0 then
            error("A production cycle needs to eather consume or produce something", 3)
        end
        for _, consume in pairs(conf.consumes) do
            if consume.product == nil then
                error("product is required to configure production circle", 4)
            end
            if consume.amount == nil then
                error("amount is required to configure production circle", 4)
            end
            if not station:canStoreProduct(consume.product) then
                error("there is no storage for " .. consume.product:getId() .. " configured in " .. station:getCallSign(), 4)
            end
            consumes[Product:toId(consume.product)] = consume.product
        end
        if isTable(conf.produces) then
            for _, produce in pairs(conf.produces) do
                if produce.product == nil then
                    error("product is required to configure production circle", 5)
                end
                if produce.amount == nil then
                    error("amount is required to configure production circle", 5)
                end
                if not station:canStoreProduct(produce.product) then
                    error("there is no storage for " .. produce.product:getId() .. " configured in " .. station:getCallSign(), 4)
                end
                produces[Product:toId(produce.product)] = produce.product
            end
        elseif not isFunction(conf.produces) then
            error("production needs to be a table or a function", 3)
        end

        local canProduce = function()
            for _, consume in pairs(conf.consumes) do
                local product = consume.product
                local amount = consume.amount

                local availableAmount = station:getProductStorage(consume.product)

                if availableAmount == nil then
                    error("there is no storage for " .. product:getId() .. " configured in " .. station:getCallSign(), 5)
                elseif availableAmount < amount then return false end
            end

            if isTable(conf.produces) then
                for _, produce in pairs(conf.produces) do
                    local product = produce.product

                    local emptySpace = station:getEmptyProductStorage(produce.product)

                    if emptySpace == nil then
                        error("there is no storage for " .. product:getId() .. " configured in " .. station:getCallSign(), 5)
                    elseif emptySpace == 0 then return false end -- we would produce as long as even a part can be stored
                end
            end
            return true
        end

        Cron.regular(cronId, function()
            if not station:isValid() then
                logWarning("Production " .. cronId .. " stopped because station is invalid.")
                Cron.abort(cronId)
            elseif canProduce() == true then
                for _, consume in pairs(conf.consumes) do
                    station:modifyProductStorage(consume.product, -1 * consume.amount)
                end

                if isTable(conf.produces) then
                    for _, produce in pairs(conf.produces) do
                        station:modifyProductStorage(produce.product, produce.amount)

                        logDebug(station:getCallSign() .. " produced " .. produce.amount .. " " .. produce.product:getId())
                    end
                elseif isFunction(conf.produces) then
                    userCallback(conf.produces)
                end
            end
        end, conf.productionTime, conf.productionTime)
    end

    --- get all the products the station produces
    --- @param self
    --- @return table[Product]
    station.getProducedProducts = function (self)
        return Util.deepCopy(produces)
    end

    --- get all the products the station consumes
    --- @param self
    --- @return table[Product]
    station.getConsumedProducts = function (self)
        return Util.deepCopy(consumes)
    end

    return station
end

--- checks if the given object has a production configured
--- @param self
--- @param station any
--- @return boolean
Station.hasProduction = function(self, station)
    return isTable(station) and
            isFunction(station.getProducedProducts) and
            isFunction(station.getConsumedProducts)
end