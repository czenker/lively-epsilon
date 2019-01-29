Order = Order or {}

Order.attack = function(self, enemy, config)
    if not isEeShipTemplateBased(enemy) then error("Expected to get a shipTemplateBased, but got " .. typeInspect(enemy), 2) end
    config = config or {}
    config.ignoreEnemies = (config.ignoreEnemies == nil and true) or config.ignoreEnemies
    if not isBoolean(config.ignoreEnemies) then error("Expected ignoreEnemies to be a boolean, but got " .. typeInspect(config.ignoreEnemies), 2) end
    if config.ignoreEnemies == false and not isEeStation(enemy) then error("Expected enemy to be a station when ignoreEnemies is false, but got " .. typeInspect(enemy), 2) end

    local order = Order:_generic(config)

    order.getEnemy = function(self)
        return enemy
    end

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