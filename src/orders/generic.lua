Order = Order or {}

--- @internal
--- @param self
--- @param config table
---   @field onExecution function the callback when the order is started to being executed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onCompletion function the callback when the order is completed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onAbort function the callback when the order is aborted. Gets the `OrderObject`, a `string` reason and the `CpuShip` or `Fleet` that executed the order.
---   @field delayAfter number how many seconds to wait before executing the next order
Order._generic = function(self, config)
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 3) end
    if config.onExecution ~= nil and not isFunction(config.onExecution) then error("Expected onExecution to be function, but got " .. typeInspect(config.onExecution   ), 3) end
    if config.onCompletion ~= nil and not isFunction(config.onCompletion) then error("Expected onCompletion to be function, but got " .. typeInspect(config.onCompletion   ), 3) end
    if config.onAbort ~= nil and not isFunction(config.onAbort) then error("Expected onAbort to be function, but got " .. typeInspect(config.onAbort), 3) end
    config.delayAfter = config.delayAfter or 0
    if not isNumber(config.delayAfter) or config.delayAfter < 0 then error("Expected delayAfter to be a positive number, but got " .. typeInspect(config.delayAfter), 3) end

    return {
        --- the callback when the order is started to being executed
        --- @internal
        --- @param self
        --- @param ship CpuShip|Fleet
        onExecution = config.onExecution or (function(self, ship) end),
        --- the callback when the order is completed
        --- @internal
        --- @param self
        --- @param ship CpuShip|Fleet
        onCompletion = config.onCompletion or (function(self, ship) end),
        --- the callback when the order is aborted
        --- @param self
        --- @internal
        --- @param reason string
        --- @param ship CpuShip|Fleet
        onAbort = config.onAbort or (function(self, reason, ship) end),
        --- get the delay until the next order is executed
        --- @internal
        --- @param self
        getDelayAfter = function(self) return config.delayAfter end,
    }
end

--- check whether the given thing is an `OrderObject`
--- @param self
--- @param order any
--- @return boolean
Order.isOrder = function(self, order)
    return isTable(order) and
        isFunction(order.getShipExecutor) and
        isFunction(order.getFleetExecutor) and
        isFunction(order.onExecution) and
        isFunction(order.onAbort) and
        isFunction(order.onCompletion)
end
