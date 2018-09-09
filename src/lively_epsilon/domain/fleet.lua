Fleet = Fleet or {}

local formationDistance = 700

-- translate the result of getOrder into a method call to set the exact same order
local getOrderToSetOrder = function(ship)
    if not isEeShip(ship) then error("Expected a ship, but got " .. type(ship), 2) end

    local order = ship:getOrder()

    if order == "Idle" then
        return "orderIdle", nil, nil, nil
    elseif order == "Roaming" then
        return "orderRoaming", nil, nil, nil
    elseif order == "Stand Ground" then
        return "orderStandGround", nil, nil, nil
    elseif order == "Defend Location" then
        local x, y = ship:getOrderTargetLocation()
        return "orderDefendLocation", x, y, nil
    elseif order == "Defend Target" then
        return "orderDefendTarget", ship:getOrderTarget(), nil, nil
    elseif order == "Fly in formation" then
        local x, y = ship:getOrderTargetLocation()
        return "orderFlyFormation", ship:getOrderTarget(), x, y, nil
    elseif order == "Fly towards" then
        local x, y = ship:getOrderTargetLocation()
        return "orderFlyTowards", x, y, nil
    elseif order == "Fly towards (ignore all)" then
        local x, y = ship:getOrderTargetLocation()
        return "orderFlyTowardsBlind", x, y, nil
    elseif order == "Attack" then
        return "orderAttack", ship:getOrderTarget(), nil, nil
    elseif order == "Dock" then
        return "orderDock", ship:getOrderTarget(), nil, nil
    else
        error("Unknown order \"" .. order .. "\"")
    end
end

Fleet.new = function(self, ships, config)
    if not isTable(ships) then error("Exptected ships to be a table, but got " .. type(ships), 2) end
    for _, ship in pairs(ships) do
        if not isEeShip(ship) then error("Expected all ships to be Ships, but got " .. type(ship), 2) end
    end

    config = config or {}
    if not isTable(config) then
        error("Expected config to be a table, but " .. type(config) .. " given.", 2)
    end
    local id = config.id or Util.randomUuid()
    if not isString(id) then
        error("Expected id to be a string, but " .. type(id) .. " given.", 2)
    end

    local currentShips = {}
    local lastShipCount
    local order, orderA, orderB, orderC = "orderIdle", nil, nil, nil -- remember the order for the fleet leader

    -- reset the flight formation.
    -- could be called initially or because a ship in fleet was destroyed
    local arrangeFormation = function()
        local nextLeft = -1 * formationDistance
        local nextRight = formationDistance
        local leader

        for i, ship in ipairs(currentShips) do
            if ship:isValid() then
                if not leader then
                    leader = ship
                    leader[order](leader, orderA, orderB, orderC)
                    ship.formationOffsetX = 0
                    ship.formationOffsetY = 0
                else
                    if i%2 == 0 then
                        ship.formationOffsetX = 0
                        ship.formationOffsetY = nextLeft
                        nextLeft = nextLeft - formationDistance
                    else
                        ship.formationOffsetX = 0
                        ship.formationOffsetY = nextRight
                        nextRight = nextRight + formationDistance
                    end

                    if ship:getOrder() == "Idle" or ship:getOrder() == "Fly in formation" or ship:getOrder() == "Roaming" then
                        -- do not change order of wingman that have a different order given by the GM
                        ship:orderFlyFormation(leader, ship.formationOffsetX, ship.formationOffsetY)
                    end
                end
            end
        end
    end

    local fleet = {
        getId = function(self)
            return id
        end,
        isValid = function(self)
            for _, ship in pairs(currentShips) do
                if ship:isValid() then return true end
            end
            return false
        end,
        getShips = function(self)
            local ret = {}
            for _, ship in pairs(currentShips) do
                if ship:isValid() then table.insert(ret, ship) end
            end
            return ret
        end,
        countShips = function(self)
            local cnt = 0
            for _, ship in pairs(currentShips) do
                if ship:isValid() then cnt = cnt + 1 end
            end
            return cnt
        end,
        getLeader = function(self)
            for _, ship in pairs(currentShips) do
                if ship:isValid() then return ship end
            end
            return nil
        end
    }

    setmetatable(fleet, {
        __index = function(table, key)
            if string.sub(key, 1, 5) == "order" then
                return function(self, a, b, c)
                    order, orderA, orderB, orderC = key, a, b, c
                    local leader = self:getLeader()

                    if leader ~= nil then
                        leader[order](leader, orderA, orderB, orderC)
                    end
                end
            end
        end
    })

    for _, ship in pairs(ships) do
        Ship:withFleet(ship, fleet)
        table.insert(currentShips, ship)
    end

    lastShipCount = fleet:countShips()

    arrangeFormation()

    Cron.regular(function(self)
        local count = fleet:countShips()
        if count == 0 then -- if all ships in the fleet are destroyed
            Cron.abort(self)
        elseif lastShipCount ~= count then -- if a ship in the fleet was just destroyed
            arrangeFormation()
            lastShipCount = count
        else -- check that every ship follows the correct orders
            for i, ship in ipairs(currentShips) do
                if ship:isValid() then
                    if ship:getCallSign() == fleet:getLeader():getCallSign() then
                        -- permanently read if the GM has changed the leaders order
                        order, orderA, orderB, orderC = getOrderToSetOrder(ship)
                    elseif ship:getOrder() == "Idle" or ship:getOrder() == "Roaming" then
                        -- make wingman fly back into their formation if GM sets them to idle
                        ship:orderFlyFormation(fleet:getLeader(), ship.formationOffsetX, ship.formationOffsetY)
                    end
                end
            end
        end
    end, 0.1)

    return fleet
end

Fleet.isFleet = function(self, thing)
    return isTable(thing) and
            isFunction(thing.getId) and
            isFunction(thing.isValid) and
            isFunction(thing.getShips) and
            isFunction(thing.countShips) and
            isFunction(thing.getLeader)
end