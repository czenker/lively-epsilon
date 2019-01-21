insulate("Order", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.orders.helper"

    describe("defend() self", function()
        testSignature(Order.defend, {}, it, assert)
        testHappyShipCase(Order.defend, function()
            return {
                args = {},
                setUp = function(ship)
                    ship.areEnemiesInRange = function() return false end
                end,
                assertOrder = "Stand Ground",
                assertOrderTarget = nil,
                assertOrderTargetLocation = nil,
                complete = function(ship)
                    for _=1,99 do Cron.tick(1) end
                end,
            }
        end, it, assert)
        testHappyFleetCase(Order.defend, function()
            return {
                args = {},
                setUp = function(fleet)
                    for _,ship in pairs(fleet:getShips()) do
                        ship.areEnemiesInRange = function() return false end
                    end
                end,
                assertOrder = "Stand Ground",
                assertOrderTarget = nil,
                assertOrderTargetLocation = nil,
                complete = function(ship)
                    for _=1,99 do Cron.tick(1) end
                end,
            }
        end, it, assert)
        it("carries out the order for 30 seconds by default (ship)", function()
            local ship = CpuShip()
            ship.areEnemiesInRange = function() return false end

            Ship:withOrderQueue(ship)
            local onCompletionCalled = 0
            local order = Order:defend({
                minDefendTime = 30,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            ship:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Stand Ground", ship:getOrder())

            for _=1,29 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Stand Ground", ship:getOrder())

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)
        it("carries out the order until there are no enemies in range for 15 seconds (ship)", function()
            local ship = CpuShip()
            local calledRange = nil
            ship.areEnemiesInRange = function(_, range)
                calledRange = range
                return true
            end

            Ship:withOrderQueue(ship)
            local onCompletionCalled = 0
            local order = Order:defend({
                range = 20000,
                minClearTime = 15,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            ship:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Stand Ground", ship:getOrder())
            assert.is_same(20000, calledRange)

            for _=1,60 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Stand Ground", ship:getOrder())

            -- no enemies for 5 seconds - is too short
            ship.areEnemiesInRange = function() return false end
            for _=1,5 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            -- ...an other enemy appears
            ship.areEnemiesInRange = function() return true end
            Cron.tick(1)
            assert.is_same(0, onCompletionCalled)

            -- ...and goes away
            ship.areEnemiesInRange = function() return false end
            for _=1,14 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)
        it("carries out the order for 30 seconds by default (fleet)", function()
            local fleet = Fleet:new({
                CpuShip(),
                CpuShip(),
                CpuShip(),
            })
            fleet:getLeader().areEnemiesInRange = function() return false end

            Fleet:withOrderQueue(fleet)
            local onCompletionCalled = 0
            local order = Order:defend({
                minDefendTime = 30,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            fleet:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Stand Ground", fleet:getLeader():getOrder())

            for _=1,29 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Stand Ground", fleet:getLeader():getOrder())

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
            local calledRange = nil
            fleet:getLeader().areEnemiesInRange = function(_, range)
                calledRange = range
                return true
            end

            Fleet:withOrderQueue(fleet)
            local onCompletionCalled = 0
            local order = Order:defend({
                range = 20000,
                minClearTime = 15,
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
            })

            fleet:addOrder(order)

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Stand Ground", fleet:getLeader():getOrder())
            assert.is_same(20000, calledRange)

            for _=1,60 do Cron.tick(1) end

            assert.is_same(0, onCompletionCalled)
            assert.is_same("Stand Ground", fleet:getLeader():getOrder())

            -- no enemies for 5 seconds - is too short
            fleet:getLeader().areEnemiesInRange = function() return false end
            for _=1,5 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            -- ...an other enemy appears
            fleet:getLeader().areEnemiesInRange = function() return true end
            Cron.tick(1)
            assert.is_same(0, onCompletionCalled)

            -- ...and goes away
            fleet:getLeader().areEnemiesInRange = function() return false end
            for _=1,14 do Cron.tick(1) end
            assert.is_same(0, onCompletionCalled)

            Cron.tick(1)
            Cron.tick(1)

            assert.is_same(1, onCompletionCalled)
        end)

        it("fails if minDefendTime is not a positive number", function()
            assert.has_error(function()
                Order:defend({
                    minDefendTime = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend({
                    minDefendTime = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend({
                    minDefendTime = -42,
                })
            end)
        end)

        it("fails if minClearTime is not a positive number", function()
            assert.has_error(function()
                Order:defend({
                    minClearTime = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend({
                    minClearTime = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend({
                    minClearTime = -42,
                })
            end)
        end)

        it("fails if range is not a positive number", function()
            assert.has_error(function()
                Order:defend({
                    range = "foo",
                })
            end)
            assert.has_error(function()
                Order:defend({
                    range = SpaceStation(),
                })
            end)
            assert.has_error(function()
                Order:defend({
                    range = -42,
                })
            end)
        end)
    end)
end)