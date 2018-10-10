Order = Order or {}

Order.dock = function(self, station, config)
    if not isEeStation(station) then error("Expected to get a station, but got " .. type(station), 2) end
    config = config or {}
    local order = Order:_generic(config)

    order.getStation = function(self)
        return station
    end

    local parentOnCompletion = order.onCompletion

    order.onCompletion = function(self, thing)
        if Fleet:isFleet(thing) then
            for _, ship in pairs(thing:getShips()) do
                if not ship:isFleetLeader() and ship:getOrder() == "Dock" and ship:getOrderTarget() == station then
                    -- reset dock order of all ships
                    ship:orderIdle()
                end
            end
        end
        parentOnCompletion(self, thing)
    end

    local parentOnAbort = order.onAbort

    order.onAbort = function(self, reason, thing)
        if Fleet:isFleet(thing) then
            for _, ship in pairs(thing:getShips()) do
                if not ship:isFleetLeader() and ship:getOrder() == "Dock" and ship:getOrderTarget() == station then
                    -- reset dock order of all ships
                    ship:orderIdle()
                end
            end
        end
        parentOnAbort(self, reason, thing)
    end

    order.getShipExecutor = function()
        return {
            go = function(self, ship)
                ship:orderDock(station)
            end,
            tick = function(self, ship)
                if not station:isValid() then
                    return false, "invalid_station"
                end
                if station:isEnemy(ship) then
                    return false, "enemy_station"
                end
                if ship:isDocked(station) then
                    if not station:getRepairDocked() or ship:getHull() == ship:getHullMax() then
                        return true
                    end
                end
            end,
        }
    end

    order.getFleetExecutor = function()
        return {
            go = function(self, fleet)
                fleet:orderDock(station)
            end,
            tick = function(self, fleet)
                if not station:isValid() then
                    return false, "invalid_station"
                end
                if station:isEnemy(fleet:getLeader()) then
                    return false, "enemy_station"
                end
                if fleet:getLeader():isDocked(station) then
                    local allReady = true
                    for _,ship in pairs(fleet:getShips()) do
                        if station:getRepairDocked() then
                            ship:orderDock(station)
                            if ship:getHull() ~= ship:getHullMax() then
                                allReady = false
                            end
                        end
                    end
                    if allReady == true then
                        return true
                    end
                end
            end,
        }
    end

    return order
end