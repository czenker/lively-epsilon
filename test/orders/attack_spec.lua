insulate("Order", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"
    require "test.orders.helper"

    describe("attack()", function()
        testSignature(Order.attack, {CpuShip():setFactionId(2)}, it, assert)
        testHappyShipCase(Order.attack, function()
            local enemy = CpuShip():setFactionId(2)
            return {
                args = { enemy },
                setUp = function(ship)
                    ship:setFactionId(1)
                end,
                assertOrder = "Attack",
                assertOrderTarget = enemy,
                assertOrderTargetLocation = nil,
                complete = function(ship)
                    enemy:destroy()
                end,
            }
        end, it, assert)
        testHappyFleetCase(Order.attack, function()
            local enemy = CpuShip():setFactionId(2)
            return {
                args = { enemy },
                setUp = function(fleet)
                    for _, ship in pairs(fleet:getShips()) do ship:setFactionId(1) end
                end,
                assertOrder = "Attack",
                assertOrderTarget = enemy,
                assertOrderTargetLocation = nil,
                complete = function(ship)
                    enemy:destroy()
                end,
            }
        end, it, assert)

        it("fails if enemy is neutral for ship", function()
            local ship = CpuShip():setFactionId(0)
            local enemy = SpaceStation():setFactionId(1)

            Ship:withOrderQueue(ship)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:attack(enemy, {
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
            assert.is_same("no_enemy", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Idle", ship:getOrder())
        end)
        it("fails if enemy is neutral for fleet", function()
            local fleet = Fleet:new({
                CpuShip():setFactionId(0),
                CpuShip():setFactionId(0),
                CpuShip():setFactionId(0),
            })
            local enemy = SpaceStation():setFactionId(1)

            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:attack(enemy, {
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
            assert.is_same("no_enemy", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Idle", fleet:getLeader():getOrder())
        end)
        it("fails if enemy turns into neutral for ship", function()
            local ship = CpuShip():setFactionId(1)
            local enemy = SpaceStation():setFactionId(2)

            Ship:withOrderQueue(ship)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:attack(enemy, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            ship:addOrder(order)

            Cron.tick(1)
            assert.is_same("Attack", ship:getOrder())

            enemy:setFactionId(1)
            Cron.tick(1)

            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("no_enemy", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Idle", ship:getOrder())
        end)
        it("fails if enemy turns into neutral for fleet", function()
            local fleet = Fleet:new({
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
            })
            local enemy = SpaceStation():setFactionId(2)

            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:attack(enemy, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            fleet:addOrder(order)

            Cron.tick(1)
            assert.is_same("Attack", fleet:getLeader():getOrder())

            enemy:setFactionId(1)
            Cron.tick(1)
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("no_enemy", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Idle", fleet:getLeader():getOrder())
        end)
        it("fails if no station or ship is given", function()
            assert.has_error(function()
                Order:attack(nil)
            end)
            assert.has_error(function()
                Order:attack("foo")
            end)
            assert.has_error(function()
                Order:attack(Asteroid())
            end)
        end)
    end)
end)