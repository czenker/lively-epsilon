Ship = Ship or {}

local stateUnknown = "unknown"
local stateWayToAsteroid = "asteroid"
local stateMining = "mining"
local stateWayHome = "home"
local stateUnloading = "unloading"

-- find a random mineable object in a certain vicinity
local function filterRandomObject(station, filterFunction, radius)
    local x, y = station:getPosition()

    local objects = {}
    for k, object in pairs(getObjectsInRadius(x, y, radius)) do
        if filterFunction(object) then objects[k] = object end
    end

    return Util.random(objects)
end

-- checks if the storage of a miner is full
local isStorageFull = function(ship, gatheredProducts)
    for product, amount in pairs(gatheredProducts) do
        if ship:getEmptyProductStorage(product) == 0 then return true end
    end
    return false
end

-- how regular to run cron
local tick = 1

--- let a ship mine near asteroids and deliver to their home station
--- @param self
--- @param ship CpuShip
--- @param homeStation SpaceStation
--- @param whenMined function gets `asteroid`, `miner` and `homeStation` as arguments. Should return a `table` where a `Product` is key and the value is a `number`.
--- @param config table
---   @field timeToUnload number (default: `15`) seconds it takes the miner to unload goods at home station
---   @field timeToMine number (default: `15`) seconds it takes the miner to mine an asteroid
---   @field timeToGoHome number (default: `900`) seconds the miner tries to mine asteroids before giving up and returning home disappointed
---   @field mineDistance number (default: `beamWeaponRange`) units how close the miner needs to be to the asteroid
---   @field maxDistanceFromHome number (default: `30000`) units how far away from home the miner looks for asteroids
---   @field maxDistanceToNext number (default: `15000`) units how far from the current asteroid the miner will look for a next one
---   @field onHeadingAsteroid function gets `miner` and `asteroid` when the miner is flying towards an asteroid
---   @field onAsteroidMined function gets `miner`, `asteroid` and the return of `whenMined`
---   @field onHeadingHome function gets `miner`, `asteroid` and all the gathered products
---   @field onUnloaded function gets `miner`, `asteroid` and all the gathered products
Ship.behaveAsMiner = function (self, ship, homeStation, whenMined, config)
    if not isEeShip(ship) then
        error("Expected ship to be a CpuShip, but got " .. typeInspect(ship), 2)
    end
    if not ship:isValid() then
        error("Expected ship to be a valid CpuShip, but got a destroyed one", 2)
    end
    if not Ship:hasStorage(ship) then
        error("Ship " .. ship:getCallSign() .. " needs to have storage configured", 2)
    end

    if not isEeStation(homeStation) then
        error("Expected homeStation to be a Station, but got " .. typeInspect(homeStation), 2)
    end
    if not Ship:hasStorage(homeStation) then
        error ("Station " .. homeStation:getCallSign() .. " needs to have storage configured", 2)
    end
    -- @TODO: handling when station is destroyed or nil - it should not be problematic when GM can assign a new home station

    if ship:getBeamWeaponRange(0) == 0 then
        logWarning(ship:getCallSign() .. " did not have a laser needed for mining, so it is given a weak one")
        ship:setBeamWeapon(0, 30, 0, 2000, 5, 5)
    end

    ship:setFactionId(homeStation:getFactionId())

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end
    config.timeToUnload = config.timeToUnload or 15
    if not isNumber(config.timeToUnload) then error("Expected timeToUnload to be a number, but got " .. typeInspect(config.timeToUnload), 2) end
    config.timeToMine = config.timeToMine or 15
    if not isNumber(config.timeToMine) then error("Expected timeToMine to be a number, but got " .. typeInspect(config.timeToMine), 2) end
    config.timeToGoHome = config.timeToGoHome or 900
    if not isNumber(config.timeToGoHome) then error("Expected timeToGoHome to be a number, but got " .. typeInspect(config.timeToGoHome), 2) end
    config.mineDistance = config.mineDistance or ship:getBeamWeaponRange(0)
    if not isNumber(config.mineDistance) then error("Expected mineDistance to be a number, but got " .. typeInspect(config.mineDistance), 2) end
    config.maxDistanceFromHome = config.maxDistanceFromHome or 30000
    if not isNumber(config.maxDistanceFromHome) then error("Expected maxDistanceFromHome to be a number, but got " .. typeInspect(config.maxDistanceFromHome), 2) end
    config.maxDistanceToNext = config.maxDistanceToNext or 15000
    if not isNumber(config.maxDistanceToNext) then error("Expected maxDistanceToNext to be a number, but got " .. typeInspect(config.maxDistanceToNext), 2) end
    config.onHeadingAsteroid = config.onHeadingAsteroid or function() end
    if not isFunction(config.onHeadingAsteroid) then error("Expected onHeadingAsteroid to be a function, but got " .. typeInspect(config.onHeadingAsteroid), 2) end
    config.onAsteroidMined = config.onAsteroidMined or function() end
    if not isFunction(config.onAsteroidMined) then error("Expected onAsteroidMined to be a function, but got " .. typeInspect(config.onAsteroidMined), 2) end
    config.onHeadingHome = config.onHeadingHome or function() end
    if not isFunction(config.onHeadingHome) then error("Expected onHeadingHome to be a function, but got " .. typeInspect(config.onHeadingHome), 2) end
    config.onUnloaded = config.onUnloaded or function() end
    if not isFunction(config.onUnloaded) then error("Expected onUnloaded to be a function, but got " .. typeInspect(config.onUnloaded), 2) end

    local cronId = "miner_" .. ship:getCallSign()
    local timeToGoHome = config.timeToGoHome -- when counter falls lower than 0 the ship will stop gathering and fly home
    local gatheredProducts = {}
    local minedAsteroids = {}
    local state = stateUnknown
    local hasWarnedAboutNoAsteroids = false
    local hasCalledHeadingHome = false

    local function isValidAsteroid(object)
        if isEeAsteroid(object) and object:isValid() then
            for other, _ in pairs(minedAsteroids) do
                -- don't mine the same asteroid twice during the same tour
                if other == object then return false end
            end
            if Util.size(minedAsteroids) >= 1 then
                -- only mine an other asteroid if it is close
                return distance(ship, object) < config.maxDistanceToNext
            else
                return true
            end
        else
            return false
        end
    end

    local stepMain, stepMineAsteroid, stepUnload, decideWhatToDo

    local onMinerDestroyed = function()
        logWarning("ship for " .. cronId .. " is no longer valid")
        state = stateUnknown
        Cron.abort(cronId)
    end

    local onHomeStationDestroyed = function()
        logWarning(ship:getCallSign() .. " has lost its home base. :(")
        state = stateUnknown
        -- @TODO: GM or script should be able to set a new home base
        Cron.abort(cronId)
    end

    local orderMine = function(asteroid)
        hasWarnedAboutNoAsteroids = false -- obviously an asteroid was found. So warn again if it goes missing.
        state = stateWayToAsteroid
        ship:orderAttack(asteroid)
        userCallback(config.onHeadingAsteroid, ship, asteroid)
    end
    local orderGoHome = function()
        state = stateWayHome
        ship:orderDock(homeStation)
        userCallback(config.onHeadingHome, ship, homeStation, gatheredProducts)
        hasCalledHeadingHome = true
    end

    stepMain = function()
        if not ship:isValid() then
            onMinerDestroyed()
        else
            timeToGoHome = timeToGoHome - tick
            if not homeStation:isValid() then
                onHomeStationDestroyed()
            elseif ship:getOrder() == "Dock" and ship:getOrderTarget() == homeStation then
                if not hasCalledHeadingHome then
                    orderGoHome()
                end
                if ship:isDocked(homeStation) then
                    stepUnload(homeStation)
                end
            else
                hasCalledHeadingHome = false
                if ship:getOrder() == "Idle" then
                    decideWhatToDo()
                end
                if ship:getOrder() == "Fly towards (ignore all)" then
                    local x, y = ship:getOrderTargetLocation()
                    local asteroids = {}
                    for _, thing in pairs(getObjectsInRadius(x, y, 2000)) do
                        if isEeAsteroid(thing) then
                            table.insert(asteroids, thing)
                        end
                    end
                    table.sort(asteroids, function(a, b)
                        return distance(a, x, y) < distance(b, x, y)
                    end)
                    if asteroids[1] ~= nil then
                        orderMine(asteroids[1])
                        logInfo(string.format("Going to mine asteroid at %d,%d because of GM interaction", math.floor(x), math.floor(y)))
                    end
                end
                if ship:getOrder() == "Attack" then
                    if not isEeAsteroid(ship:getOrderTarget()) then
                        decideWhatToDo()
                    elseif distance(ship, ship:getOrderTarget()) < config.mineDistance then
                        stepMineAsteroid(ship:getOrderTarget())
                    end
                else
                    state = stateUnknown
                end
            end

        end
        -- @TODO: search new home base
    end

    stepMineAsteroid = function(asteroid)
        local timeToMine = config.timeToMine

        -- @TODO: callback
        logDebug(ship:getCallSign() .. " starts mining asteroid")
        state = stateMining

        Cron.regular(cronId, function()
            if not ship:isValid() then
                onMinerDestroyed()
            elseif not homeStation:isValid() then
                onHomeStationDestroyed()
            elseif not ship:getOrder() == "Attack" or ship:getOrderTarget() ~= asteroid then
                logDebug(ship:getCallSign() .. " aborted mining because of changed orders")
                state = stateUnknown
                stepMain()
                Cron.regular(cronId, stepMain, tick, tick)
            else
                timeToGoHome = timeToGoHome - tick
                timeToMine = timeToMine - tick
                if timeToMine <= 0 then
                    local rewards = whenMined(ship:getOrderTarget(), ship, homeStation)
                    local x, y = ship:getOrderTarget():getPosition()
                    ExplosionEffect():setPosition(x, y):setSize(150)

                    for product, amount in pairs(rewards) do
                        if amount > 0 then
                            if ship:canStoreProduct(product) and homeStation:canStoreProduct(product) then
                                ship:modifyProductStorage(product, amount)
                                gatheredProducts[product] = (gatheredProducts[product] or 0) + amount
                                logDebug(ship:getCallSign() .. " gathered " .. amount .. " " .. product:getId() .. " from mining")

                                if ship:getEmptyProductStorage(product) == 0 then
                                    timeToGoHome = 0
                                    logDebug(ship:getCallSign() .. " will head home, because store for " .. product:getId() .. " is full")
                                end
                            else
                                logWarning("discarded mined " .. product:getId() .. " because miner or home base can not store it")
                            end
                        end
                    end

                    userCallback(config.onAsteroidMined, ship, asteroid, rewards)
                    minedAsteroids[ship:getOrderTarget()] = true
                    decideWhatToDo()
                    Cron.regular(cronId, stepMain, tick, tick)
                end
            end
        end, tick)
    end

    stepUnload = function(station)
        local timeToUnload = config.timeToUnload

        -- @TODO: callback
        logDebug(ship:getCallSign() .. " starts unloading mined goods at " .. station:getCallSign())

        state = stateUnloading
        Cron.regular(cronId, function()
            if not ship:isValid() then
                onMinerDestroyed()
            elseif not homeStation:isValid() then
                onHomeStationDestroyed()
            elseif not ship:getOrder() == "Dock" or ship:getOrderTarget() ~= station then
                logDebug(ship:getCallSign() .. " aborted unloading because of changed orders")
                state = stateUnknown
                Cron.regular(cronId, stepMain, tick, tick)
            else
                timeToGoHome = timeToGoHome - tick
                timeToUnload = timeToUnload - tick
                if timeToUnload <= 0 then
                    for product, _ in pairs(gatheredProducts) do
                        local amount = ship:getProductStorage(product)
                        ship:modifyProductStorage(product, -1 * amount)
                        if homeStation:canStoreProduct(product) then
                            homeStation:modifyProductStorage(product, amount)
                            logInfo(ship:getCallSign() .. " unloaded " .. amount .. " " .. product:getId() .. " to " .. homeStation:getCallSign())
                        else
                            logWarning(product:getId() .. " gathered by " .. ship:getCallSign() .. " was discarded, because " .. homeStation:getCallSign() .. "can not store it")
                        end
                    end

                    userCallback(config.onUnloaded, ship, homeStation, gatheredProducts)

                    gatheredProducts = {}
                    timeToGoHome = config.timeToGoHome
                    minedAsteroids = {}

                    decideWhatToDo()
                    Cron.regular(cronId, stepMain, tick, tick)
                end
            end
        end, tick)
    end

    decideWhatToDo = function()
        if timeToGoHome <= 0 then
            if Util.size(gatheredProducts) == 0 then
                logWarning(ship:getCallSign() .. " is heading home without any gathered minerals")
            else
                logDebug(ship:getCallSign() .. " is heading home to " .. homeStation:getCallSign() .. " because time is up.")
            end
            orderGoHome()
        elseif isStorageFull(ship, gatheredProducts) then
            logDebug(ship:getCallSign() .. " is heading home to " .. homeStation:getCallSign() .. " because storage is full.")
            orderGoHome()
        else
            local next = filterRandomObject(homeStation, isValidAsteroid, config.maxDistanceFromHome)
            if next == nil then
                if Util.size(minedAsteroids) == 0 then
                    if not hasWarnedAboutNoAsteroids then
                        logWarning(ship:getCallSign() .. " did not find any mineable asteroids around " .. homeStation:getCallSign())
                        hasWarnedAboutNoAsteroids = true
                    end
                else
                    logDebug(ship:getCallSign() .. " is heading home to " .. homeStation:getCallSign() .. " because no more asteroids where found.")
                    orderGoHome()
                end
            else
                orderMine(next)
            end
        end
    end

    decideWhatToDo()
    Cron.regular(cronId, stepMain, tick, tick)

    ship.getMinerState = function(self)
        return state
    end
end