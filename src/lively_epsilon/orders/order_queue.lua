Ship = Ship or {}
Fleet = Fleet or {}

local createOrderQueue = function(label, validator, cronIdFunc)
    return function(self, object)
        if not validator(object) then error("Expected " .. label .. ", but got " .. typeInspect(object), 2) end

        local currentOrder = nil
        local currentOrderExecutor = nil
        local orderQueue = {}
        local cronId = cronIdFunc(object)
        local delayUntil = nil

        local tick

        -- abort the currently executed order
        local function abort(reason)
            userCallback(currentOrder.onAbort, currentOrder, reason, object)
            object:orderIdle()
            currentOrder, currentOrderExecutor, delayUntil = nil, nil, nil
            tick()
        end
        tick = function()
            if not object:isValid() then logInfo("aborting order queue " .. cronId .. " because " .. label .. " is no longer valid") end
            if currentOrder == nil and (delayUntil == nil or delayUntil <= Cron.now()) then
                delayUntil = nil
                currentOrder = table.remove(orderQueue, 1)
                if currentOrder == nil then
                    -- no more orders to carry out -> go to sleep
                    Cron.abort(cronId)
                else
                    currentOrderExecutor = currentOrder["get" .. label .. "Executor"](currentOrder)
                    currentOrderExecutor:go(object)
                    userCallback(currentOrder.onExecution, currentOrder, object)
                end
            end
            if currentOrder ~= nil then
                if (isEeShip(object) and object:isValid() and object:getOrder() == "Idle") or (Fleet:isFleet(object) and object:isValid() and object:getLeader():getOrder() == "Idle") then
                    currentOrderExecutor:go(object)
                end
                local result, errorCode = currentOrderExecutor:tick(object)
                if result == true then
                    userCallback(currentOrder.onCompletion, currentOrder, object)
                    delayUntil = Cron.now() + currentOrder:getDelayAfter()

                    currentOrder, currentOrderExecutor = nil, nil
                    tick()
                elseif result == false then
                    if not isString(errorCode) then
                        logWarning("Expected errorCode when tick() of an order fails, but got " .. typeInspect(errorCode))
                        errorCode = "unknown"
                    else
                        logDebug("Executing order for " .. cronId .. " failed with error code " .. errorCode)
                    end
                    abort(errorCode)
                end
            end
        end

        object.addOrder = function(self, order)
            if not Order:isOrder(order) then error("Expected an order, but got " .. typeInspect(order), 2) end
            table.insert(orderQueue, order)

            if currentOrder == nil then
                Cron.regular(cronId, tick, 0.1, 0.1)
                tick()
            end
        end

        object.abortCurrentOrder = function(self)
            if currentOrder ~= nil then
                logInfo("Excuting order for " .. cronId .. " was aborted because of a request to do so")
                abort("user")
            else
                logDebug("No current order to stop for " .. cronId)
            end
        end

        object.flushOrders = function()
            orderQueue = {}
        end

        object.forceOrderNow = function(self, order)
            if not Order:isOrder(order) then error("Expected an order, but got " .. typeInspect(order), 2) end

            self:flushOrders()
            self:abortCurrentOrder()
            self:addOrder(order)
        end
    end
end

Ship.withOrderQueue = createOrderQueue("Ship", isEeShip, function(ship) return ship:getCallSign() .. "_order_queue" end)
Ship.hasOrderQueue = function(self, ship)
    return isEeShip(ship) and
            isFunction(ship.addOrder)
end

Fleet.withOrderQueue = createOrderQueue("Fleet", function(thing) return Fleet:isFleet(thing) end, function(fleet) return fleet:getId() .. "_order_queue" end)
Fleet.hasOrderQueue = function(self, fleet)
    return Fleet:isFleet(fleet) and
            isFunction(fleet.addOrder)
end