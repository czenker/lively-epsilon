Order = Order or {}

Order.flyTo = function(self, x, y, config)
    if not isNumber(x) then error("Expected x to be a number, but got " .. type(x), 2) end
    if not isNumber(y) then error("Expected y to be a number, but got " .. type(y), 2) end
    config = config or {}
    local order = Order:_generic(config)
    config.minDistance = config.minDistance or 500
    if not isNumber(config.minDistance) or config.minDistance < 0 then error("Expected minDistance to be a positive number, but got " .. type(config.minDistance), 2) end
    config.ignoreEnemies = config.ignoreEnemies or false
    if not isBoolean(config.ignoreEnemies) then error("Expected ignoreEnemies to be a boolean, but got " .. type(config.ignoreEnemies), 2) end

    order.getLocation = function()
        return x, y
    end

    order.getShipExecutor = function()
        return {
            go = function(self, ship)
                if config.ignoreEnemies then
                    ship:orderFlyTowardsBlind(x, y)
                else
                    ship:orderFlyTowards(x, y)
                end
            end,
            tick = function(self, ship)
                if distance(ship, x, y) < config.minDistance then
                    return true
                end
            end,
        }
    end
    order.getFleetExecutor = function()
        return {
            go = function(self, fleet)
                if config.ignoreEnemies then
                    fleet:orderFlyTowardsBlind(x, y)
                else
                    fleet:orderFlyTowards(x, y)
                end
            end,
            tick = function(self, fleet)
                if distance(fleet:getLeader(), x, y) < config.minDistance then
                    return true
                end
            end,
        }
    end

    return order
end