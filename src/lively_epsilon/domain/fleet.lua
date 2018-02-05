Fleet = Fleet or {}

local formationDistance = 700


Fleet.new = function(self, ships)
    if not isTable(ships) then error("Exptected ships to be a table, but got " .. type(ships), 2) end
    for _, ship in pairs(ships) do
        if not isEeShip(ship) then error("Expected all ships to be Ships, but got " .. type(ship), 2) end
    end

    local currentShips = {}
    local lastShipCount
    local order, orderA, orderB, orderC = "orderIdle", nil, nil, nil -- remember the order for the fleet leader

    local arrangeFormation = function()
        local nextLeft = -1 * formationDistance
        local nextRight = formationDistance
        local leader

        for i, ship in ipairs(currentShips) do
            if ship:isValid() then
                if not leader then
                    leader = ship
                    leader[order](leader, orderA, orderB, orderC)
                elseif i%2 == 0 then
                    ship:orderFlyFormation(leader, 0, nextLeft)
                    nextLeft = nextLeft - formationDistance
                else
                    ship:orderFlyFormation(leader, 0, nextRight)
                    nextRight = nextRight + formationDistance
                end
            end
        end
    end

    local fleet = {
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
        if count == 0 then
            Cron.abort(self)
        elseif lastShipCount ~= count then
            arrangeFormation()
            lastShipCount = count
        end
    end, 0.1)

    return fleet
end

Fleet.isFleet = function(self, thing)
    return isTable(thing) and
            isFunction(thing.isValid) and
            isFunction(thing.getShips) and
            isFunction(thing.countShips) and
            isFunction(thing.getLeader)
end