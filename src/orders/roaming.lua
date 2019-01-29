Order = Order or {}

Order.roaming = function(self, config)
    config = config or {}
    config.duration = config.duration
    if not isNil(config.duration) and not (isNumber(config.duration) and config.duration > 0) then error("Expected duration to be a positive number, but got " .. typeInspect(config.duration), 2) end

    local order = Order:_generic(config)

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