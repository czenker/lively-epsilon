Ship = Ship or {}
Fleet = Fleet or {}

local createOrderQueue = function(label, validator, cronIdFunc)
    --- @param self
    --- @param object
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
            if not object:isValid() then
                logInfo("aborting order queue " .. cronId .. " because " .. label .. " is no longer valid")
                Cron.abort(cronId)
                return
            end
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
                    -- if the order was successfully executed
                    userCallback(currentOrder.onCompletion, currentOrder, object)
                    delayUntil = Cron.now() + currentOrder:getDelayAfter()

                    currentOrder, currentOrderExecutor = nil, nil
                    tick()
                elseif result == false then
                    -- if the order can no longer be executed
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

        --- add an order that is executed after all other orders
        --- @param self
        --- @param order Order
        --- @return self
        object.addOrder = function(self, order)
            if not Order:isOrder(order) then error("Expected an order, but got " .. typeInspect(order), 2) end
            table.insert(orderQueue, order)

            if currentOrder == nil then
                Cron.regular(cronId, tick, 0.1, 0.1)
                tick()
            end
            return self
        end

        --- abort the current order
        --- @param self
        --- @return self
        object.abortCurrentOrder = function(self)
            if currentOrder ~= nil then
                logInfo("Excuting order for " .. cronId .. " was aborted because of a request to do so")
                abort("user")
            else
                logDebug("No current order to stop for " .. cronId)
            end
            return self
        end

        --- remove all orders that would be executed after the current one
        --- @param self
        --- @return self
        object.flushOrders = function(self)
            orderQueue = {}
            return self
        end

        --- abort all orders and start executing the given order
        --- @param self
        --- @param order Order
        --- @return self
        object.forceOrderNow = function(self, order)
            if not Order:isOrder(order) then error("Expected an order, but got " .. typeInspect(order), 2) end

            self:flushOrders()
            self:abortCurrentOrder()
            self:addOrder(order)
        end

        return object
    end
end

--- adds an OrderQueue to the ship
--- @param self
--- @param object CpuShip
--- @return CpuShip
Ship.withOrderQueue = createOrderQueue("Ship", isEeShip, function(ship) return ship:getCallSign() .. "_order_queue" end)

--- check if the given thing is a ship with order queue
--- @param self
--- @param ship any
--- @return boolean
Ship.hasOrderQueue = function(self, ship)
    return isEeShip(ship) and
            isFunction(ship.addOrder) and
            isFunction(ship.abortCurrentOrder) and
            isFunction(ship.flushOrders) and
            isFunction(ship.forceOrderNow)
end

--- adds an OrderQueue to the fleet
--- @param self
--- @param object Fleet
--- @return Fleet
Fleet.withOrderQueue = createOrderQueue("Fleet", function(thing) return Fleet:isFleet(thing) end, function(fleet) return fleet:getId() .. "_order_queue" end)
--- check if the thing is a fleet with an orderQueue
--- @param self
--- @param fleet any
--- @return boolean
Fleet.hasOrderQueue = function(self, fleet)
    return Fleet:isFleet(fleet) and
            isFunction(fleet.addOrder)
end