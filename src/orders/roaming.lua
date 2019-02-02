Order = Order or {}

--- order to roam around
--- @param self
--- @param config
---   @field duration number how many seconds to roam around before considering the order done
---   @field onExecution function the callback when the order is started to being executed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onCompletion function the callback when the order is completed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onAbort function the callback when the order is aborted. Gets the `OrderObject`, a `string` reason and the `CpuShip` or `Fleet` that executed the order.
---   @field delayAfter number how many seconds to wait before executing the next order
--- @return OrderObject
Order.roaming = function(self, config)
    config = config or {}
    config.duration = config.duration or 60
    if not isNil(config.duration) and not (isNumber(config.duration) and config.duration > 0) then error("Expected duration to be a positive number, but got " .. typeInspect(config.duration), 2) end

    local order = Order:_generic(config)

    --- @internal
    order.getShipExecutor = function()
        local timeToEnd
        if isNumber(config.duration) then timeToEnd = Cron.now() + config.duration end
        return {
            go = function(self, ship)
                ship:orderRoaming()
            end,
            tick = function(self, ship)
                if isNumber(timeToEnd) and timeToEnd >= Cron.now() then return true end
            end,
        }
    end

    --- @internal
    order.getFleetExecutor = function()
        local timeToEnd
        if isNumber(config.duration) then timeToEnd = Cron.now() + config.duration end
        return {
            go = function(self, fleet)
                fleet:orderRoaming()
            end,
            tick = function(self, fleet)
                if isNumber(timeToEnd) and timeToEnd >= Cron.now() then return true end
            end,
        }
    end

    return order
end