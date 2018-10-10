Order = Order or {}

Order._generic = function(self, config)
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 3) end
    if config.onExecution ~= nil and not isFunction(config.onExecution) then error("Expected onExecution to be function, but got " .. type(config.onExecution   ), 3) end
    if config.onCompletion ~= nil and not isFunction(config.onCompletion) then error("Expected onCompletion to be function, but got " .. type(config.onCompletion   ), 3) end
    if config.onAbort ~= nil and not isFunction(config.onAbort) then error("Expected onAbort to be function, but got " .. type(config.onAbort), 3) end
    config.delayAfter = config.delayAfter or 0
    if not isNumber(config.delayAfter) or config.delayAfter < 0 then error("Expected delayAfter to be a positive number, but got " .. type(config.delayAfter), 3) end

    return {
        onExecution = config.onExecution or (function(self, ship) end),
        onCompletion = config.onCompletion or (function(self, ship) end),
        onAbort = config.onAbort or (function(self, reason, ship) end),
        getDelayAfter = function() return config.delayAfter end,
    }
end

Order.isOrder = function(self, order)
    return isTable(order) and
        isFunction(order.getShipExecutor) and
        isFunction(order.getFleetExecutor) and
        isFunction(order.onExecution) and
        isFunction(order.onAbort) and
        isFunction(order.onCompletion)
end
