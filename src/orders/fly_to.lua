Order = Order or {}

--- order to fly to a specific location
--- @param self
--- @param x number
--- @param y number
--- @param config table
---   @field minDistance number (default: `500`) the order is considered completed when the ship is this far from the target location
---   @field ignoreEnemies boolean (default: `false`) do not attack enemies on the way
---   @field onExecution function the callback when the order is started to being executed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onCompletion function the callback when the order is completed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onAbort function the callback when the order is aborted. Gets the `OrderObject`, a `string` reason and the `CpuShip` or `Fleet` that executed the order.
---   @field delayAfter number how many seconds to wait before executing the next order
--- @return OrderObject
Order.flyTo = function(self, x, y, config)
    if not isNumber(x) then error("Expected x to be a number, but got " .. typeInspect(x), 2) end
    if not isNumber(y) then error("Expected y to be a number, but got " .. typeInspect(y), 2) end
    config = config or {}
    local order = Order:_generic(config)
    config.minDistance = config.minDistance or 500
    if not isNumber(config.minDistance) or config.minDistance < 0 then error("Expected minDistance to be a positive number, but got " .. typeInspect(config.minDistance), 2) end
    config.ignoreEnemies = config.ignoreEnemies or false
    if not isBoolean(config.ignoreEnemies) then error("Expected ignoreEnemies to be a boolean, but got " .. typeInspect(config.ignoreEnemies), 2) end

    --- get the target location
    --- @param self
    --- @return number,number
    order.getLocation = function(self)
        return x, y
    end

    --- @internal
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
    --- @internal
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