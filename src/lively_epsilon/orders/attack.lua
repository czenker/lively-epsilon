Order = Order or {}

Order.attack = function(self, enemy, config)
    if not isEeShipTemplateBased(enemy) then error("Expected to get a shipTemplateBased, but got " .. type(enemy), 2) end
    config = config or {}
    local order = Order:_generic(config)

    order.getEnemy = function(self)
        return enemy
    end

    order.getShipExecutor = function()
        return {
            go = function(self, ship)
                ship:orderAttack(enemy)
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
                fleet:orderAttack(enemy)
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