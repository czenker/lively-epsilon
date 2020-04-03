Order = Order or {}

local orderDefendLocation = function(order, x, y, config)
    if not isNumber(x) then error("Expected x to be a number, but got " .. typeInspect(x), 3) end
    if not isNumber(y) then error("Expected y to be a number, but got " .. typeInspect(y), 3) end
    local areEnemiesInRange = function(ship, range)
        for _,thing in pairs(getObjectsInRadius(x, y, range)) do
            if isEeShipTemplateBased(thing) and thing:isValid() and ship:isEnemy(thing) then return true end
        end
        return false
    end

    --- @internal
    order.getShipExecutor = function()
        local noEndBefore = Cron.now() + config.minDefendTime
        return {
            go = function(self, ship)
                ship:orderDefendLocation(x, y)
            end,
            tick = function(self, ship)
                if areEnemiesInRange(ship, config.range) then
                    noEndBefore = math.max(noEndBefore, Cron.now() + config.minClearTime)
                elseif Cron.now() >= noEndBefore then
                    return true
                end
            end,
        }
    end

    --- @internal
    order.getFleetExecutor = function()
        local noEndBefore = Cron.now() + config.minDefendTime
        return {
            go = function(self, fleet)
                fleet:orderDefendLocation(x, y)
            end,
            tick = function(self, fleet)
                if areEnemiesInRange(fleet:getLeader(), config.range) then
                    noEndBefore = math.max(noEndBefore, Cron.now() + config.minClearTime)
                elseif Cron.now() >= noEndBefore then
                    return true
                end
            end,
        }
    end
    return order
end

local orderDefendTarget = function(order, target, config)
    if not isEeShipTemplateBased(target) then error("Expected target to be a shipTemplateBased, but got " .. typeInspect(target), 3) end
    --- @internal
    order.getShipExecutor = function()
        local noEndBefore = Cron.now() + config.minDefendTime
        return {
            go = function(self, ship)
                ship:orderDefendTarget(target)
            end,
            tick = function(self, ship)
                if not target:isValid() then
                    return false, "destroyed"
                elseif ship:isEnemy(target) then
                    return false, "is_enemy"
                elseif target:areEnemiesInRange(config.range) then
                    noEndBefore = math.max(noEndBefore, Cron.now() + config.minClearTime)
                elseif Cron.now() >= noEndBefore then
                    return true
                end
            end,
        }
    end

    --- @internal
    order.getFleetExecutor = function()
        local noEndBefore = Cron.now() + config.minDefendTime
        return {
            go = function(self, fleet)
                fleet:orderDefendTarget(target)
            end,
            tick = function(self, fleet)
                if not target:isValid() then
                    return false, "destroyed"
                elseif fleet:getLeader():isEnemy(target) then
                    return false, "is_enemy"
                elseif target:areEnemiesInRange(config.range) then
                    noEndBefore = math.max(noEndBefore, Cron.now() + config.minClearTime)
                elseif Cron.now() >= noEndBefore then
                    return true
                end
            end,
        }
    end
    return order
end

local orderDefendSelf = function(order, config)
    --- @internal
    order.getShipExecutor = function()
        local noEndBefore = Cron.now() + config.minDefendTime
        return {
            go = function(self, ship)
                ship:orderStandGround()
            end,
            tick = function(self, ship)
                if ship:areEnemiesInRange(config.range) then
                    noEndBefore = math.max(noEndBefore, Cron.now() + config.minClearTime)
                elseif Cron.now() >= noEndBefore then
                    return true
                end
            end,
        }
    end

    --- @internal
    order.getFleetExecutor = function()
        local noEndBefore = Cron.now() + config.minDefendTime
        return {
            go = function(self, fleet)
                fleet:orderStandGround()
            end,
            tick = function(self, fleet)
                if fleet:getLeader():areEnemiesInRange(config.range) then
                    noEndBefore = math.max(noEndBefore, Cron.now() + config.minClearTime)
                elseif Cron.now() >= noEndBefore then
                    return true
                end
            end,
        }
    end
    return order
end

--- defend a location a `ShipTemplateBased` or yourself
--- @param self
--- @param arg1 number|ShipTemplateBased (optional) the x coordinate of the defense location or the `ShipTemplateBased` to defend. If not given the ship will defend itself.
--- @param arg2 number (optional) the y coordinate of the defense location
--- @param config table (optional)
---   @field minDefendTime number (default: 60) the number of seconds to execute this order at least
---   @field minClearTime number (default: 10) the minimum number of seconds there should be no enemies in range
---   @field range number (default: `30000`) how far to check for enemies
---   @field onExecution function the callback when the order is started to being executed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onCompletion function the callback when the order is completed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onAbort function the callback when the order is aborted. Gets the `OrderObject`, a `string` reason and the `CpuShip` or `Fleet` that executed the order.
---   @field delayAfter number how many seconds to wait before executing the next order
--- @return OrderObject
Order.defend = function(self, arg1, arg2, config)
    local version
    if isEeObject(arg1) then
        if not isNil(config) or not (isNil(arg2) or isTable(arg2)) then error("Invalid number of arguments.", 2) end
        version = "target"
        config = arg2
        arg2 = nil
    elseif not isNil(arg2) then
        if isNil(arg1) or not (isNil(config) or isTable(config)) then error("Invalid number of arguments.", 2) end
        version = "location"
    else
        if not(isNil(arg1) or isTable(arg1)) or not isNil(arg2) or not isNil(config) then error("Invalid number of arguments.", 2) end
        version = "self"
        config = arg1
        arg1, arg2 = nil, nil
    end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    config.minDefendTime = config.minDefendTime or 60
    if not isNumber(config.minDefendTime) or config.minDefendTime < 0 then error("Expected minDefendTime to be a positive number, but got " .. typeInspect(config.minDefendTime), 2) end
    config.minClearTime = config.minClearTime or 10
    if not isNumber(config.minClearTime) or config.minClearTime < 0 then error("Expected minClearTime to be a positive number, but got " .. typeInspect(config.minClearTime), 2) end
    config.range = config.range or 30000
    if not isNumber(config.range) or config.range < 0 then error("Expected range to be a positive number, but got " .. typeInspect(config.range), 2) end
    local order = Order:_generic(config)

    if version == "location" then
        return orderDefendLocation(order, arg1, arg2, config)
    elseif version == "target" then
        return orderDefendTarget(order, arg1, config)
    elseif version == "self" then
        return orderDefendSelf(order, config)
    end
end