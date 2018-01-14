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

local tick = 2

Ship.orderMiner = function (self, ship, homeStation, whenMined)
    if not isEeShip(ship) or not ship:isValid() then
        error("Invalid ship given", 2)
    end
    if not Ship:hasStorage(ship) then
        error("ship " .. ship:getCallSign() .. " needs to have a storage configured", 2)
    end

    if not isEeStation(homeStation) or not homeStation:isValid() then
        error("Invalid station given", 2)
    end
    if not Ship:hasStorage(homeStation) then
        error ("station " .. homeStation:getCallSign() .. " needs to have a storage configured", 2)
    end

    if ship:getBeamWeaponRange(0) == 0 then
        logWarning(ship:getCallSign() .. " did not have a laser needed for mining, so it is given a weak one")
        ship:setBeamWeapon(0, 30, 0, 2000, 5, 5)
    end

    ship:setFactionId(homeStation:getFactionId())

    local cronId = "miner_" .. ship:getCallSign()
    local target
    local timeToGoHome -- when counter falls lower than 0 the ship will stop gethering  and fly home
    local timeToMine
    local timeToUnload
    local gatheredProducts = {}
    local minedAsteroids = {}

    local function isValidAsteroid(object)
        if isEeAsteroid(object) and object:isValid() then
            for other, _ in pairs(minedAsteroids) do
                -- don't mine the same asteroid twice during the same tour
                if other == object then return false end
            end
            if Util.size(minedAsteroids) >= 1 then
                -- only mine an other asteroid if it is close
                return distance(ship, object) < (getLongRangeRadarRange() / 2)
            else
                return true
            end
        else
            return false
        end
    end

    Cron.regular(cronId, function()
        if not ship:isValid() then
            logError("ship for " .. cronId .. " is no longer valid")
            Cron.abort(cronId)
        elseif not homeStation:isValid() then
            logError(ship:getCallSign() .. " has lost its home base. :(")
            ship:orderIdle()
            target = nil
            Cron.abort(cronId)
        elseif target == nil then
            if timeToGoHome ~= nil and timeToGoHome <= 0 then
                target = homeStation
                timeToUnload = nil
                logInfo(ship:getCallSign() .. " is flying back to home base")
                ship:orderDock(target)
            else
                target = filterRandomObject(homeStation, isValidAsteroid)
                if target == nil then
                    if Util.size(gatheredProducts) > 0 then
                        -- if ship has already gathered stuff
                        logDebug(ship:getCallSign() .. " did not find any more asteroids and will return home")
                        timeToGoHome = 0
                    else
                        logWarning(ship:getCallSign() .. " did not find a valid asteroid in range to mine")
                    end
                else
                    timeToMine = nil
                    ship:orderAttack(target)
                end
            end
        elseif target == homeStation then
            if ship:isDocked(homeStation) then
                if timeToUnload == nil then
                    timeToUnload = 15
                else
                    timeToUnload = timeToUnload - tick
                end
                if timeToUnload <= 0 then
                    for product, _ in pairs(gatheredProducts) do
                        local amount = ship:getProductStorage(product)
                        ship:modifyProductStorage(product, -1 * amount)
                        homeStation:modifyProductStorage(product, amount)
                        logInfo(ship:getCallSign() .. " unloaded " .. amount .. " " .. product .. " to " .. homeStation:getCallSign())
                        gatheredProducts[product] = nil
                    end

                    timeToGoHome = nil
                    minedAsteroids = {}
                    target = nil
                end
            end
        elseif isEeAsteroid(target) then
            if timeToGoHome == nil then
                timeToGoHome = 900
            else
                timeToGoHome = timeToGoHome - tick
            end

            if not isValidAsteroid(target) then
                target = nil
            elseif distance(ship, target) < 2000 then
                if timeToMine == nil then
                    timeToMine = 15
                else
                    timeToMine = timeToMine - tick
                end

                if timeToMine <= 0 then
                    local rewards = whenMined(target, ship, homeStation)

                    for product, amount in pairs(rewards) do
                        if amount > 0 then
                            product = Product:toId(product)
                            if ship:canStoreProduct(product) and homeStation:canStoreProduct(product) then
                                ship:modifyProductStorage(product, amount)
                                gatheredProducts[product] = true
                                logInfo(ship:getCallSign() .. " gathered " .. amount .. " " .. product .. " from mining")

                                if ship:getEmptyProductStorage(product) == 0 then
                                    timeToGoHome = 0
                                    logInfo(ship:getCallSign() .. " will head home, because store for " .. product .. " is full")
                                end
                            end
                        end
                    end

                    minedAsteroids[target] = true
                    target = nil
                end
            end
        end
    end, tick, 1)
end