Ship = Ship or {}

local function filterRandomObject(station, filterFunction, radius)
    local x, y = station:getPosition()
    radius = radius or getLongRangeRadarRange()

    local objects = {}
    for k, object in pairs(getObjectsInRadius(x, y, radius)) do
        if filterFunction(object) then objects[k] = object end
    end

    return Util.random(objects)
end

Ship.orderBuyer = function (self, ship, homeStation, product)
    product = Product.toId(product)

    if not isEeShip(ship) or not ship:isValid() then
        error("Invalid ship given", 2)
    end
    if not hasStorage(ship) then
        error ("ship " .. ship:getCallSign() .. " needs to have a storage configured", 2)
    end
    if not ship:canStoreProduct(product) then
        error ("ship " .. ship:getCallSign() .. " can not store " .. product, 2)
    end

    if not isEeStation(homeStation) or not homeStation:isValid() then
        error("Invalid station given", 2)
    end
    if not hasStorage(homeStation) then
        error ("station " .. homeStation:getCallSign() .. " needs to have a storage configured", 2)
    end

    ship = Ship:enrich(ship)
    homeStation = Station:enrich(homeStation)

    ship:setFactionId(homeStation:getFactionId())

    local cronId = "trader" .. ship:getCallSign()
    local target
    local dockingTo

    local function isValidSeller(object)
        if isEeStation(object) and object:isValid() and not object:isEnemy(object) and object:getCallSign() ~= homeStation:getCallSign() and hasStorage(object) and hasMerchant(object) then
            -- it is a friendly station that has not yet exploded - hurray!
            object = Station:enrich(object)

            local stationSelling = object:getMaxProductSelling(product)
            local minBuying = ship.maxStorage / 10

            if homeStation:getEmptyProductStorage(product) < minBuying then return false end

            if stationSelling ~= nil and stationSelling >= minBuying then return true end
        end
        return false
    end

    Cron.regular(cronId, function()
        if not ship:isValid() then
            print("ship for " .. cronId .. " is no longer valid")
            Cron.abort(cronId)
        elseif not homeStation:isValid() then
            print(ship:getCallSign() .. " has lost its home base. :(")
            ship:orderIdle()
            dockingTo = nil
            Cron.abort(cronId)
        elseif ship:getProductStorage(product) > 0 then
            if ship:isDocked(homeStation) then
                -- unload cargo
                local amount = ship:getProductStorage(product)
                ship:modifyProductStorage(product, -1 * amount)
                homeStation:modifyProductStorage(product, amount)
                print(ship:getCallSign() .. " unloaded " .. amount .. " " .. product .. " at " .. homeStation:getCallSign())
            else
                if dockingTo ~= homeStation then
                    ship:orderDock(homeStation)
                    dockingTo = homeStation
                end
            end
        elseif target == nil then
            local seller = filterRandomObject(homeStation, isValidSeller)

            if seller == nil then
                if dockingTo ~= homeStation then
                    ship:orderDock(homeStation)
                    dockingTo = homeStation
                end
            else
                print(ship:getCallSign() .. " is going to buy " .. product .. " from " .. seller:getCallSign())
                target = seller
            end
        elseif not isValidSeller(target) then
            print(ship:getCallSign() .. " discarded the current seller")
            target = nil
        elseif ship:isDocked(target) then
            local amount = math.min(
                ship.maxStorage,
                target:getMaxProductSelling(product),
                homeStation:getEmptyProductStorage(product)
            )

            ship:modifyProductStorage(product, amount)
            target:modifyProductStorage(product, -1 * amount)
            print(ship:getCallSign() .. " bought " .. amount .. " " .. product .. " at " .. target:getCallSign())
            target = nil
        else
            if dockingTo ~= target then
                ship:orderDock(target)
                dockingTo = target
            end
        end
    end, 5, 1)
end