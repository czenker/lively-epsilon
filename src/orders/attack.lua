Order = Order or {}

--- order to attack an enemy
--- @param self
--- @param enemy ShipTemplateBased
--- @param config table
---   @field ignoreEnemies boolean (default: `true`)
---   @field onExecution function the callback when the order is started to being executed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onCompletion function the callback when the order is completed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onAbort function the callback when the order is aborted. Gets the `OrderObject`, a `string` reason and the `CpuShip` or `Fleet` that executed the order.
---   @field delayAfter number how many seconds to wait before executing the next order
--- @return OrderObject
Order.attack = function(self, enemy, config)
    if not isEeShipTemplateBased(enemy) then error("Expected to get a shipTemplateBased, but got " .. typeInspect(enemy), 2) end
    config = config or {}
    config.ignoreEnemies = (config.ignoreEnemies == nil and true) or config.ignoreEnemies
    if not isBoolean(config.ignoreEnemies) then error("Expected ignoreEnemies to be a boolean, but got " .. typeInspect(config.ignoreEnemies), 2) end
    if config.ignoreEnemies == false and not isEeStation(enemy) then error("Expected enemy to be a station when ignoreEnemies is false, but got " .. typeInspect(enemy), 2) end

    local order = Order:_generic(config)

    --- get the enemy that is attacked
    --- @param self
    --- @return ShipTemplateBased
    order.getEnemy = function(self)
        return enemy
    end

    --- get the executor for a ship
    --- @internal
    order.getShipExecutor = function()
        return {
            go = function(self, ship)
                if config.ignoreEnemies then
                    ship:orderAttack(enemy)
                else
                    local x, y = enemy:getPosition()
                    ship:orderFlyTowards(x, y)
                end
            end,
            tick = function(self, ship)
                if not enemy:isValid() then
                    return true
                end
                if not ship:isEnemy(enemy) then
                    return false, "no_enemy"
                end
            end,
        }
    end

    --- get the executor for a fleet
    --- @internal
    order.getFleetExecutor = function()
        return {
            go = function(self, fleet)
                if config.ignoreEnemies then
                    fleet:orderAttack(enemy)
                else
                    local x, y = enemy:getPosition()
                    fleet:orderFlyTowards(x, y)
                end
            end,
            tick = function(self, fleet)
                if not enemy:isValid() then
                    return true
                end
                if not fleet:getLeader():isEnemy(enemy) then
                    return false, "no_enemy"
                end
            end,
        }
    end

    return order
end