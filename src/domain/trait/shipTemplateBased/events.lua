ShipTemplateBased = ShipTemplateBased or {}

--- listen for events on the `ShipTemplateBased`
--- @deprecated I am not sure if i will leave it in or remove it
--- @param self
--- @param shipTemplateBased ShipTemplateBased
--- @param config table
---   @field onDestruction nil|function gets `shipTemplateBased` as argument.
---   @field onEnemyDetection nil|function gets `shipTemplateBased` as argument.
---   @field onEnemyClear nil|function gets `shipTemplateBased` as argument.
---   @field onBeingAttacked nil|function gets `shipTemplateBased` as argument.
--- @return ShipTemplateBased
ShipTemplateBased.withEvents  = function(self, shipTemplateBased, config)
    if not isEeShipTemplateBased(shipTemplateBased) then error("Expected a shipTemplateBased, but got " .. typeInspect(shipTemplateBased), 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    if config.onDestruction ~= nil and not isFunction(config.onDestruction) then error("Expected onDestruction to be a function, but got " .. typeInspect(config.onDestruction), 2) end
    if config.onEnemyDetection ~= nil and not isFunction(config.onEnemyDetection) then error("Expected onEnemyDetection to be a function, but got " .. typeInspect(config.onEnemyDetection), 2) end
    if config.onEnemyClear ~= nil and not isFunction(config.onEnemyClear) then error("Expected onEnemyClear to be a function, but got " .. typeInspect(config.onEnemyClear), 2) end
    if config.onBeingAttacked ~= nil and not isFunction(config.onBeingAttacked) then error("Expected onBeingAttacked to be a function, but got " .. typeInspect(config.onBeingAttacked), 2) end

    if isFunction(config.onDestruction) then
        local tick = 0.1

        Cron.regular(function(self)
            if not shipTemplateBased:isValid() then
                Cron.abort(self)
                userCallback(config.onDestruction, shipTemplateBased)
            end

        end, tick)
    end

    if isFunction(config.onEnemyDetection) or isFunction(config.onEnemyClear) then
        local tick = 0.1
        local cronId = Util.randomUuid()

        local waitForEnter, waitForLeave

        local longRangeRadarRange = 30000
        if isFunction(shipTemplateBased.getLongRangeRadarRange) then
            longRangeRadarRange = shipTemplateBased:getLongRangeRadarRange()
        end

        waitForEnter = function()
            if not shipTemplateBased:isValid() then
                Cron.abort(tick)
            elseif shipTemplateBased:areEnemiesInRange(longRangeRadarRange) then
                Cron.regular(cronId, waitForLeave, tick, tick)
                userCallback(config.onEnemyDetection, shipTemplateBased)
            end
        end

        waitForLeave = function()
            if not shipTemplateBased:isValid() then
                Cron.abort(tick)
            elseif not shipTemplateBased:areEnemiesInRange(longRangeRadarRange) then
                Cron.regular(cronId, waitForEnter, tick, tick)
                userCallback(config.onEnemyClear, shipTemplateBased)
            end
        end

        Cron.regular(cronId, waitForEnter, tick)
    end

    if isFunction(config.onBeingAttacked) then
        local tick = 0.1
        local lockResetDelay = 90
        local hull = shipTemplateBased:getHull()
        local shield = Util.totalShieldLevel(shipTemplateBased)
        local lock = false
        local cronId = Util.randomUuid()
        local cronIdLockReset = cronId .. "-lock"

        Cron.regular(cronId, function()
            if not shipTemplateBased:isValid() then
                Cron.abort(cronId)
                Cron.abort(cronIdLockReset)
            else
                local currentHull = shipTemplateBased:getHull()
                local currentShield = Util.totalShieldLevel(shipTemplateBased)

                if currentHull < hull or currentShield < shield then
                    if lock == true then
                        -- not checking for enemies if lock is active to prevent expensive calls
                        -- just assume that any further damage done also comes from enemies
                        Cron.once(cronIdLockReset, function() lock = false end, lockResetDelay)
                    elseif shipTemplateBased:areEnemiesInRange(5000) then
                        lock = true
                        Cron.once(cronIdLockReset, function() lock = false end, lockResetDelay)
                        userCallback(config.onBeingAttacked, shipTemplateBased)
                    end
                end
                hull = currentHull
                shield = currentShield
            end

        end, tick)

    end

    return shipTemplateBased
end