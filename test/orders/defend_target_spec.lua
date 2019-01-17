insulate("Order", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"
    require "test.orders.helper"

    describe("defend() target", function()
        testSignature(Order.defend, {SpaceStation()}, it, assert)
        testHappyShipCase(Order.defend, function()
            local station = SpaceStation()
            station.areEnemiesInRange = function() return false end

            return {
                args = { station },
                setUp = function() end,
                assertOrder = "Defend Target",
                assertOrderTarget = station,
                assertOrderTargetLocation = nil,
                complete = function(ship)
                    for _=1,99 do Cron.tick(1) end
                end,
            }
        end, it, assert)
        testHappyFleetCase(Order.defend, function()
            local station = SpaceStation()
            station.areEnemiesInRange = function() return false end

            return {
                args = { station },
                setUp = function() end,
                assertOrder = "Defend Target",
                assertOrderTarget = station,
                assertOrderTargetLocation = nil,
                complete = function(ship)
                    for _=1,99 do Cron.tick(1) end
                end,
            }
        end, it, assert)
        it("carries out the order for 30 seconds by default (ship)", function()
            local ship = CpuShip()
            local station = SpaceStation()
            station.areEnemiesInRange = function() return false end

            Ship:withOrderQueue(ship)
            local onCompletionCalled = 0
            local order = Order:defend(station, {
                minDefendTime = 30,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            ship:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Target", ship:getOrder())
            assert.is_same(station, ship:getOrderTarget())

            for _=1,29 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Target", ship:getOrder())
            assert.is_same(station, ship:getOrderTarget())

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)
        it("carries out the order until there are no enemies in range for 15 seconds (ship)", function()
            local ship = CpuShip()
            local station = SpaceStation()
            local rangeCalled = nil
            station.areEnemiesInRange = function(_, range)
                rangeCalled = range
                return true
            end

            Ship:withOrderQueue(ship)
            local onCompletionCalled = 0
            local order = Order:defend(station, {
                range = 20000,
                minClearTime = 15,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            ship:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Target", ship:getOrder())
            assert.is_same(station, ship:getOrderTarget())
            assert.is_same(20000, rangeCalled)

            for _=1,60 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Target", ship:getOrder())
            assert.is_same(station, ship:getOrderTarget())

            -- no enemies for 5 seconds - is too short
            station.areEnemiesInRange = function() return false end
            for _=1,5 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            -- ...an other enemy appears
            station.areEnemiesInRange = function() return true end
            Cron.tick(1)
            assert.is_same(0, onCompletionCalled)

            -- ...and goes away
            station.areEnemiesInRange = function() return false end
            for _=1,14 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)
        it("carries out the order for 60 seconds by default (fleet)", function()
            local fleet = Fleet:new({
                CpuShip(),
                CpuShip(),
                CpuShip(),
            })
            local station = SpaceStation()
            station.areEnemiesInRange = function() return false end

            Fleet:withOrderQueue(fleet)
            local onCompletionCalled = 0
            local order = Order:defend(station, {
                minDefendTime = 30,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            fleet:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Target", fleet:getLeader():getOrder())
            assert.is_same(station, fleet:getLeader():getOrderTarget())

            for _=1,29 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Target", fleet:getLeader():getOrder())
            assert.is_same(station, fleet:getLeader():getOrderTarget())

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)

        it("carries out the order until there are no enemies in range for 15 seconds (fleet)", function()
            local fleet = Fleet:new({
                CpuShip(),
                CpuShip(),
                CpuShip(),
            })
            local station = SpaceStation()
            local rangeCalled = nil
            station.areEnemiesInRange = function(_, range)
                rangeCalled = range
                return true
            end

            Fleet:withOrderQueue(fleet)
            local onCompletionCalled = 0
            local order = Order:defend(station, {
                range = 20000,
                minClearTime = 15,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            fleet:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Target", fleet:getLeader():getOrder())
            assert.is_same(station, fleet:getLeader():getOrderTarget())
            assert.is_same(20000, rangeCalled)

            for _=1,60 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Target", fleet:getLeader():getOrder())
            assert.is_same(station, fleet:getLeader():getOrderTarget())

            -- no enemies for 5 seconds - is too short
            station.areEnemiesInRange = function() return false end
            for _=1,5 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            -- ...an other enemy appears
            station.areEnemiesInRange = function() return true end
            Cron.tick(1)
            assert.is_same(0, onCompletionCalled)

            -- ...and goes away
            station.areEnemiesInRange = function() return false end
            for _=1,14 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)

        it("aborts if target is enemy of ship", function()
            local ship = CpuShip():setFactionId(1)
            local station = SpaceStation():setFactionId(2)
            station.areEnemiesInRange = function() return false end

            Ship:withOrderQueue(ship)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:defend(station, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            ship:addOrder(order)

            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("is_enemy", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Idle", ship:getOrder())
        end)
        it("aborts if target is enemy of fleet", function()
            local fleet = Fleet:new({
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1)
            })
            local station = SpaceStation():setFactionId(2)
            station.areEnemiesInRange = function() return false end

            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:defend(station, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            fleet:addOrder(order)

            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("is_enemy", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Idle", fleet:getLeader():getOrder())
        end)
        it("aborts if target is destroyed (ship)", function()
            local ship = CpuShip()
            local station = SpaceStation()
            station.areEnemiesInRange = function() return false end

            Ship:withOrderQueue(ship)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:defend(station, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            ship:addOrder(order)
            assert.is_same(0, onAbortCalled)
            Cron.tick(1)

            station:destroy()
            Cron.tick(1)

            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("destroyed", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Idle", ship:getOrder())
        end)
        it("aborts if target is destroyed (fleet)", function()
            local fleet = Fleet:new({
                CpuShip(),
                CpuShip(),
                CpuShip(),
            })
            local station = SpaceStation()
            station.areEnemiesInRange = function() return false end

            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:defend(station, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            fleet:addOrder(order)
            assert.is_same(0, onAbortCalled)
            Cron.tick(1)

            station:destroy()
            Cron.tick(1)

            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("destroyed", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Idle", fleet:getLeader():getOrder())
        end)

        it("fails if parameter is an invalid target", function()
            assert.has_error(function()
                Order:defend(42)
            end)
            assert.has_error(function()
                Order:defend("foo")
            end)
            assert.has_error(function()
                Order:defend(Asteroid())
            end)
        end)

        it("fails if minDefendTime is not a positive number", function()
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    minDefendTime = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    minDefendTime = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    minDefendTime = -42,
                })
            end)
        end)

        it("fails if minClearTime is not a positive number", function()
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    minClearTime = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    minClearTime = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    minClearTime = -42,
                })
            end)
        end)

        it("fails if range is not a positive number", function()
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    range = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    range = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend(SpaceStation(), {
                    range = -42,
                })
            end)
        end)
    end)
end)