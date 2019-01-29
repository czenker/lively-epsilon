Ship = Ship or {}

-- onDocking
-- onUndocking
-- onDockInitiation
Ship.withEvents  = function(self, ship, config)
    if not isEeShip(ship) then error("Expected a ship, but got " .. typeInspect(ship), 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    if config.onDocking ~= nil and not isFunction(config.onDocking) then error("Expected onDocking to be a function, but got " .. typeInspect(config.onDocking), 2) end
    if config.onUndocking ~= nil and not isFunction(config.onUndocking) then error("Expected onUndocking to be a function, but got " .. typeInspect(config.onUndocking), 2) end
    if config.onDockInitiation ~= nil and not isFunction(config.onDockInitiation) then error("Expected onDockInitiation to be a function, but got " .. typeInspect(config.onDockInitiation), 2) end

    local parentConfig = {
        onDestruction = config.onDestruction,
        onEnemyDetection = config.onEnemyDetection,
        onEnemyClear = config.onEnemyClear,
        onBeingAttacked = config.onBeingAttacked,
    }
    if Util.size(parentConfig) > 0 then
        ShipTemplateBased:withEvents(ship, parentConfig)
    end

    if isFunction(config.onDocking) or isFunction(config.onUndocking) then
        local tick = 0.1
        local cronId = Util.randomUuid()
        local dockedStation

        local waitForDock, waitForUndock

        waitForDock = function()
            if not ship:isValid() then
                Cron.abort(cronId)
            elseif ship:getOrder() == "Dock" then
                local station = ship:getOrderTarget()
                if ship:isDocked(station) then
                    dockedStation = station
                    Cron.regular(cronId, waitForUndock, tick, tick)
                    userCallback(config.onDocking, ship, station)
                end
            end
        end

        waitForUndock = function()
            if not ship:isValid() then
                Cron.abort(cronId)
            elseif not dockedStation:isValid() or not ship:isDocked(dockedStation) then
                Cron.regular(cronId, waitForDock, tick, tick)
                userCallback(config.onUndocking, ship, dockedStation)
                dockedStation = nil
            end
        end

        Cron.regular(cronId, waitForDock, tick)
    end

    if isFunction(config.onDockInitiation) then
        local tick = 0.1
        local cronId = Util.randomUuid()
        local targetStation

        local waitForDockInitiation, waitForOrderChange

        waitForDockInitiation = function()
            if not ship:isValid() then
                Cron.abort(cronId)
            elseif ship:getOrder() == "Dock" then
                local station = ship:getOrderTarget()
                if station:isValid() and distance(ship, station) < 5000 then
                    targetStation = station
                    Cron.regular(cronId, waitForOrderChange, tick, tick)
                    userCallback(config.onDockInitiation, ship, targetStation)
                end
            end
        end

        waitForOrderChange = function()
            if not ship:isValid() then
                Cron.abort(cronId)
            elseif ship:getOrder() ~= "Dock" or ship:getOrderTarget() ~= targetStation then
                waitForDockInitiation()
                Cron.regular(cronId, waitForDockInitiation, tick, tick)
            end
        end

        Cron.regular(cronId, waitForDockInitiation, tick)
    end
end