Order = Order or {}
--- Order to dock at a station
--- @param self
--- @param station SpaceStation
--- @param config table
---   @field waitForRepair boolean (default: `true`) if the `CpuShip` or `Fleet` should wait until hull damage is repaired. It does not prevent the station from repairing the ship if it supports it. The ship will just not wait until it is fully repaired.
---   @field waitForMissileRestock boolean (default: `true`) if the `CpuShip` or `Fleet` should wait until missiles are restocked. It does not prevent the station from restocking the ship, but it will just not wait until it is fully restocked.
---   @field waitForShieldRecharge boolean (default: `true`) if the `CpuShip` or `Fleet` should wait until the shields are fully recharged. It does not prevent the station from recharging the ship, but it will just not wait until it is fully recharged.
---   @field onExecution function the callback when the order is started to being executed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onCompletion function the callback when the order is completed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onAbort function the callback when the order is aborted. Gets the `OrderObject`, a `string` reason and the `CpuShip` or `Fleet` that executed the order.
---   @field delayAfter number how many seconds to wait before executing the next order
--- @return OrderObject
Order.dock = function(self, station, config)
    if not isEeStation(station) then error("Expected to get a station, but got " .. typeInspect(station), 2) end
    config = config or {}
    config.waitForRepair = (config.waitForRepair == nil and true) or config.waitForRepair
    if not isBoolean(config.waitForRepair) then error("Expected waitForRepair to be boolean, but got " .. typeInspect(config.waitForRepair), 2) end
    config.waitForMissileRestock = (config.waitForMissileRestock == nil and true) or config.waitForMissileRestock
    if not isBoolean(config.waitForMissileRestock) then error("Expected waitForMissileRestock to be boolean, but got " .. typeInspect(config.waitForMissileRestock), 2) end
    config.waitForShieldRecharge = (config.waitForShieldRecharge == nil and true) or config.waitForShieldRecharge
    if not isBoolean(config.waitForShieldRecharge) then error("Expected waitForShieldRecharge to be boolean, but got " .. typeInspect(config.waitForShieldRecharge), 2) end
    local order = Order:_generic(config)

    --- get the station to dock to
    --- @param self
    --- @return SpaceStation
    order.getStation = function(self)
        return station
    end

    local parentOnCompletion = order.onCompletion

    --- the callback when the order is completed
    --- @internal
    --- @param self
    --- @param ship CpuShip|Fleet
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

    --- the callback when the order is aborted
    --- @param self
    --- @internal
    --- @param reason string
    --- @param ship CpuShip|Fleet
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
        if config.waitForRepair and station:getRepairDocked() and ship:getHull() < ship:getHullMax() then
            return false
        end
        -- @see CpuShip::update
        if config.waitForMissileRestock then
            for _, weapon in pairs({"hvli", "homing", "mine", "nuke", "emp"}) do
                if ship:getWeaponStorageMax(weapon) > ship:getWeaponStorage(weapon) then return false end
            end
        end
        if config.waitForShieldRecharge then
            local shields, shieldsMax = 0, 0
            for i=0,ship:getShieldCount()-1 do
                shields = shields + ship:getShieldLevel(i)
                shieldsMax = shieldsMax + ship:getShieldMax(i)
            end
            if shields < shieldsMax then return false end
        end
        return true
    end

    --- @internal
    order.getShipExecutor = function()
        return {
            go = function(self, ship)
                ship:orderDock(station)
            end,
            tick = function(self, ship)
                if not station:isValid() then
                    return false, "invalid_station"
                end
                if ship:isEnemy(station) then
                    return false, "enemy_station"
                end
                if ship:isDocked(station) and isReady(ship) then
                    return true
                end
            end,
        }
    end

    --- @internal
    order.getFleetExecutor = function()
        return {
            go = function(self, fleet)
                fleet:orderDock(station)
            end,
            tick = function(self, fleet)
                if not station:isValid() then
                    return false, "invalid_station"
                end
                if fleet:getLeader():isEnemy(station) then
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