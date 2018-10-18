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
                if not ship:isFleetLeader() and ((ship:getOrder() == "Dock" and ship:getOrderTarget() == station) or ship:isDocked(station)) then
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
                if (ship:getOrder() == "Dock" and ship:getOrderTarget() == station) or ship:isDocked(station) then
                    -- reset dock order of all ships
                    ship:orderIdle()
                end
            end
        end
        parentOnAbort(self, reason, thing)
    end

    -- returns true if a ship is repaired, recharged and refilled on missiles
    local function isReady(ship)
        if station:getRepairDocked() and ship:getHull() < ship:getHullMax() then
            return false
        end
        -- @see CpuShip::update
        for _, weapon in pairs({"hvli", "homing", "mine", "nuke", "emp"}) do
            if ship:getWeaponStorageMax(weapon) > ship:getWeaponStorage(weapon) then return false end
        end
        local shields, shieldsMax = 0, 0
        for i=0,ship:getShieldCount()-1 do
            shields = shields + ship:getShieldLevel(i)
            shieldsMax = shieldsMax + ship:getShieldMax(i)
        end
        if shields < shieldsMax then return false end
        return true
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
                if ship:isDocked(station) and isReady(ship) then
                    return true
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
                        if not isReady(ship) then
                            allReady = false
                            if not ship:isFleetLeader() and not (ship:getOrder() == "Dock" and ship:getOrderTarget() == station) then
                                ship:orderDock(station)
                            end
                        elseif not ship:isFleetLeader() and (ship:getOrder() == "Dock" and ship:getOrderTarget() == station) then
                            ship:orderIdle() -- make it undock
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