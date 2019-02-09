Order = Order or {}

--- order to use a wormhole
--- @param self
--- @param wormhole WormHole
--- @param config table
---   @field onExecution function the callback when the order is started to being executed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onCompletion function the callback when the order is completed. Gets the `OrderObject` and the `CpuShip` or `Fleet` that executed the order.
---   @field onAbort function the callback when the order is aborted. Gets the `OrderObject`, a `string` reason and the `CpuShip` or `Fleet` that executed the order.
---   @field onBreakUp function the callback when the fleet is close enough to the wormhole that the formation is broken up. Gets the `OrderObject` and the `Fleet` that executed the order.
---   @field delayAfter number how many seconds to wait before executing the next order
--- @return OrderObject
Order.use = function(self, wormhole, config)
    if not isEeWormHole(wormhole) then error("Expected wormhole to be a WormHole, but got " .. typeInspect(wormhole), 2) end
    config = config or {}
    if not isNil(config.onBreakUp) and not isFunction(config.onBreakUp) then error("Expected onBreakUp to be a function, but got " .. typeInspect(config.onBreakUp), 2) end
    local order = Order:_generic(config)

    --- get the Wormhole to use
    --- @param self
    --- @return WormHole
    order.getWormHole = function(self)
        return wormhole
    end

    local hasJumped = function(ship)
        return distance(ship, wormhole:getTargetPosition())  < 5000
    end

    --- @internal
    order.getShipExecutor = function()
        return {
            go = function(self, ship)
                if wormhole:isValid() then
                    ship:orderFlyTowards(wormhole:getPosition())
                end
            end,
            tick = function(self, ship)
                if not wormhole:isValid() then
                    return false, "invalid_target"
                elseif hasJumped(ship) then
                    return true
                end
            end,
        }
    end
    --- @internal
    order.getFleetExecutor = function()
        local onBreakUpCalled = false
        return {
            go = function(self, fleet)
                if not wormhole:isValid() then
                    return
                else
                    fleet:orderFlyTowards(wormhole:getPosition())
                end
            end,
            tick = function(self, fleet)
                if not wormhole:isValid() then
                    return false, "invalid_target"
                elseif hasJumped(fleet:getLeader()) then
                    local allJumped = true
                    for _, ship in pairs(fleet:getShips()) do
                        if hasJumped(ship) then
                            if ship:isFleetLeader() then
                                ship:orderStandGround()
                            elseif (ship:getOrder() == "Fly towards (ignore all)" and ship:getOrderTargetLocation() == wormhole:getPosition()) or ship:getOrder() == "Stand Ground" then
                                ship:orderIdle() -- fly back in formation
                            end
                        else
                            allJumped = false
                        end
                    end
                    if allJumped then return true end
                elseif distance(fleet:getLeader(), wormhole) < 3000 then
                    for _, ship in pairs(fleet:getShips()) do
                        if hasJumped(ship) then
                            ship:orderStandGround()
                        else
                            ship:orderFlyTowardsBlind(wormhole:getPosition())
                        end
                    end
                    if not onBreakUpCalled then
                        userCallback(config.onBreakUp, order, fleet)
                        onBreakUpCalled = true
                    end
                end
            end,
        }
    end

    return order
end