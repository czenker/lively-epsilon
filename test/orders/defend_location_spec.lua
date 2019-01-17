insulate("Order", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"
    require "test.orders.helper"

    describe("defend() location", function()
        testSignature(Order.defend, {5000, 0}, it, assert)
        testHappyShipCase(Order.defend, function()
            return {
                args = {5000, 0},
                setUp = function(ship)
                    _G.getObjectsInRadius = function() return {} end
                end,
                assertOrder = "Defend Location",
                assertOrderTarget = nil,
                assertOrderTargetLocation = {5000, 0},
                complete = function(ship)
                    for _=1,99 do Cron.tick(1) end
                end,
            }
        end, it, assert)
        testHappyFleetCase(Order.defend, function()
            return {
                args = {5000, 0},
                setUp = function(fleet)
                    _G.getObjectsInRadius = function() return {} end
                end,
                assertOrder = "Defend Location",
                assertOrderTarget = nil,
                assertOrderTargetLocation = {5000, 0},
                complete = function(ship)
                    for _=1,99 do Cron.tick(1) end
                end,
            }
        end, it, assert)
        it("carries out the order for 30 seconds (ship)", function()
            local ship = CpuShip()
            _G.getObjectsInRadius = function() return {} end

            Ship:withOrderQueue(ship)
            local onCompletionCalled = 0
            local order = Order:defend(5000, 0, {
                minDefendTime = 30,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            ship:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Location", ship:getOrder())
            assert.is_same({5000, 0}, {ship:getOrderTargetLocation()})

            for _=1,29 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Location", ship:getOrder())
            assert.is_same({5000, 0}, {ship:getOrderTargetLocation()})

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)
        it("carries out the order until there are no enemies in range for 15 seconds (ship)", function()
            local ship = CpuShip():setFactionId(1)
            local calledRange = nil
            _G.getObjectsInRadius = function(_, _, range)
                calledRange = range
                return {CpuShip():setFactionId(2)}
            end

            Ship:withOrderQueue(ship)
            local onCompletionCalled = 0
            local order = Order:defend(5000, 0, {
                range = 20000,
                minClearTime = 15,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            ship:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Location", ship:getOrder())
            assert.is_same({5000, 0}, {ship:getOrderTargetLocation()})
            assert.is_same(20000, calledRange)

            for _=1,60 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Location", ship:getOrder())
            assert.is_same({5000, 0}, {ship:getOrderTargetLocation()})

            -- no enemies for 5 seconds - is too short
            _G.getObjectsInRadius = function() return {} end
            for _=1,5 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            -- ...an other enemy appears
            _G.getObjectsInRadius = function() return {CpuShip():setFactionId(2)} end
            Cron.tick(1)
            assert.is_same(0, onCompletionCalled)

            -- ...and goes away
            _G.getObjectsInRadius = function() return {} end
            for _=1,14 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)
        it("carries out the order for 30 seconds (fleet)", function()
            local fleet = Fleet:new({
                CpuShip(),
                CpuShip(),
                CpuShip(),
            })
            fleet:getLeader().areEnemiesInRange = function() return false end

            Fleet:withOrderQueue(fleet)
            local onCompletionCalled = 0
            local order = Order:defend(5000, 0, {
                minDefendTime = 30,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            fleet:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Location", fleet:getLeader():getOrder())
            assert.is_same({5000, 0}, {fleet:getLeader():getOrderTargetLocation()})

            for _=1,29 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Location", fleet:getLeader():getOrder())
            assert.is_same({5000, 0}, {fleet:getLeader():getOrderTargetLocation()})

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)

        it("carries out the order until there are no enemies in range for 15 seconds (fleet)", function()
            local fleet = Fleet:new({
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
            })
            local calledRange = nil
            _G.getObjectsInRadius = function(_, _, range)
                calledRange = range
                return {CpuShip():setFactionId(2)}
            end

            Fleet:withOrderQueue(fleet)
            local onCompletionCalled = 0
            local order = Order:defend(5000, 0, {
                range = 20000,
                minClearTime = 15,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            fleet:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Location", fleet:getLeader():getOrder())
            assert.is_same({5000, 0}, {fleet:getLeader():getOrderTargetLocation()})
            assert.is_same(20000, calledRange)

            for _=1,60 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Defend Location", fleet:getLeader():getOrder())
            assert.is_same({5000, 0}, {fleet:getLeader():getOrderTargetLocation()})

            -- no enemies for 5 seconds - is too short
            _G.getObjectsInRadius = function() return {} end
            for _=1,5 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            -- ...an other enemy appears
            _G.getObjectsInRadius = function() return {CpuShip():setFactionId(2)} end
            Cron.tick(1)
            assert.is_same(0, onCompletionCalled)

            -- ...and goes away
            _G.getObjectsInRadius = function() return {} end
            for _=1,14 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)

        it("fails if any coordinate is not a number", function()
            assert.has_error(function()
                Order:defend(nil, 42)
            end)
            assert.has_error(function()
                Order:defend(5000, nil)
            end)
            assert.has_error(function()
                Order:defend("foo", 42)
            end)
            assert.has_error(function()
                Order:defend(5000, "foo")
            end)
            assert.has_error(function()
                Order:defend(SpaceStation(), 42)
            end)
            assert.has_error(function()
                Order:defend(5000, SpaceStation())
            end)
        end)

        it("fails if minDefendTime is not a positive number", function()
            assert.has_error(function()
                Order:defend(0, 0, {
                    minDefendTime = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend(0, 0, {
                    minDefendTime = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend(0, 0, {
                    minDefendTime = -42,
                })
            end)
        end)

        it("fails if minClearTime is not a positive number", function()
            assert.has_error(function()
                Order:defend(0, 0, {
                    minClearTime = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend(0, 0, {
                    minClearTime = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend(0, 0, {
                    minClearTime = -42,
                })
            end)
        end)

        it("fails if range is not a positive number", function()
            assert.has_error(function()
                Order:defend(0, 0, {
                    range = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend(0, 0, {
                    range = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend(0, 0, {
                    range = -42,
                })
            end)
        end)
    end)
end)