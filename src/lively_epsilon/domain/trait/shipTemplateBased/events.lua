ShipTemplateBased = ShipTemplateBased or {}

-- onDestruction
-- onEnemyDetection
-- onEnemyClear
-- onBeingAttacked
ShipTemplateBased.withEvents  = function(self, shipTemplateBased, config)
    if not isEeShipTemplateBased(shipTemplateBased) then error("Expected a shipTemplateBased, but got " .. type(shipTemplateBased), 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    if config.onDestruction ~= nil and not isFunction(config.onDestruction) then error("Expected onDestruction to be a function, but got " .. type(config.onDestruction), 2) end
    if config.onEnemyDetection ~= nil and not isFunction(config.onEnemyDetection) then error("Expected onEnemyDetection to be a function, but got " .. type(config.onEnemyDetection), 2) end
    if config.onEnemyClear ~= nil and not isFunction(config.onEnemyClear) then error("Expected onEnemyClear to be a function, but got " .. type(config.onEnemyClear), 2) end
    if config.onBeingAttacked ~= nil and not isFunction(config.onBeingAttacked) then error("Expected onBeingAttacked to be a function, but got " .. type(config.onBeingAttacked), 2) end

    if isFunction(config.onDestruction) then
        local tick = 0.1

        Cron.regular(function(self)
            if not shipTemplateBased:isValid() then
                Cron.abort(self)
                local status, error = pcall(config.onDestruction, shipTemplateBased)
                if not status then
                    local errorMsg = "An error occurred while calling onDestruction for " .. shipTemplateBased:getCallSign()
                    if isString(error) then
                        errorMsg = errorMsg .. ": " .. error
                    end
                    logError(errorMsg)
                end
            end

        end, tick)
    end

    if isFunction(config.onEnemyDetection) or isFunction(config.onEnemyClear) then
        local tick = 0.1
        local cronId = Util.randomUuid()

        local waitForEnter, waitForLeave

        waitForEnter = function()
            if not shipTemplateBased:isValid() then
                Cron.abort(tick)
            elseif shipTemplateBased:areEnemiesInRange(getLongRangeRadarRange()) then
                Cron.regular(cronId, waitForLeave, tick, tick)
                if isFunction(config.onEnemyDetection) then
                    local status, error = pcall(config.onEnemyDetection, shipTemplateBased)
                    if not status then
                        local errorMsg = "An error occurred while calling onEnemyDetection for " .. shipTemplateBased:getCallSign()
                        if isString(error) then
                            errorMsg = errorMsg .. ": " .. error
                        end
                        logError(errorMsg)
                    end
                end
            end
        end

        waitForLeave = function()
            if not shipTemplateBased:isValid() then
                Cron.abort(tick)
            elseif not shipTemplateBased:areEnemiesInRange(getLongRangeRadarRange()) then
                Cron.regular(cronId, waitForEnter, tick, tick)
                if isFunction(config.onEnemyClear) then
                    local status, error = pcall(config.onEnemyClear, shipTemplateBased)
                    if not status then
                        local errorMsg = "An error occurred while calling onEnemyClear for " .. shipTemplateBased:getCallSign()
                        if isString(error) then
                            errorMsg = errorMsg .. ": " .. error
                        end
                        logError(errorMsg)
                    end
                end
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
                        local status, error = pcall(config.onBeingAttacked, shipTemplateBased)
                        if not status then
                            local errorMsg = "An error occurred while calling onBeingAttacked for " .. shipTemplateBased:getCallSign()
                            if isString(error) then
                                errorMsg = errorMsg .. ": " .. error
                            end
                            logError(errorMsg)
                        end
                    end
                end
                hull = currentHull
                shield = currentShield
            end

        end, tick)

    end
end