insulate("Ship", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("Ship:withOrderQueue()", function()
        it("should create a ship with order queue", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            assert.is_true(Ship:hasOrderQueue(ship))
        end)

        it("fails if parameter is not a ship", function()
            assert.has_error(function()
                Ship:withOrderQueue()
            end)
            assert.has_error(function()
                Ship:withOrderQueue(42)
            end)
            assert.has_error(function()
                Ship:withOrderQueue(SpaceStation())
            end)
            assert.has_error(function()
                Ship:withOrderQueue(Fleet:new({CpuShip(), CpuShip(), CpuShip()}))
            end)
        end)
    end)

    describe("Fleet:withOrderQueue()", function()
        it("should create a fleet with order queue", function()
            local fleet = Fleet:new({CpuShip(), CpuShip(), CpuShip()})
            Fleet:withOrderQueue(fleet)

            assert.is_true(Fleet:hasOrderQueue(fleet))
        end)

        it("fails if parameter is not a fleet", function()
            assert.has_error(function()
                Fleet:withOrderQueue()
            end)
            assert.has_error(function()
                Fleet:withOrderQueue(42)
            end)
            assert.has_error(function()
                Fleet:withOrderQueue(SpaceStation())
            end)
            assert.has_error(function()
                Fleet:withOrderQueue(CpuShip())
            end)
        end)
    end)

    describe("addOrder()", function()
        it("immediately carries out an order if there are no other order queued", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(1000, 0))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})
        end)

        it("waits until the first order is issued", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            assert.is_same("Idle", ship:getOrder())
            Cron.tick(1)
            assert.is_same("Idle", ship:getOrder())

            ship:addOrder(Order:flyTo(1000, 0))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})
        end)

        it("queues orders and carries them out consecutively", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(1000, 0))
            ship:addOrder(Order:flyTo(0, 1000))
            ship:addOrder(Order:flyTo(-1000, 0))

            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            ship:setPosition(1000, 0)
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 1000}, {ship:getOrderTargetLocation()})

            ship:setPosition(0, 1000)
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({-1000, 0}, {ship:getOrderTargetLocation()})
        end)

        it("carries out an order until the next one is given", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(0, 0))

            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 0}, {ship:getOrderTargetLocation()})

            ship:setPosition(1000, 0)
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 0}, {ship:getOrderTargetLocation()})

            ship:addOrder(Order:flyTo(0, 1000))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 1000}, {ship:getOrderTargetLocation()})
        end)

        it("fails if parameter is not an order", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            assert.has_error(function()
                ship:addOrder()
            end)
            assert.has_error(function()
                ship:addOrder(42)
            end)
            assert.has_error(function()
                ship:addOrder(CpuShip())
            end)
        end)
    end)

    describe("abortCurrentOrder()", function()
        it("ship idles if there is no next order", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil

            local order = Order:flyTo(1000, 0, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end
            })
            ship:addOrder(order)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same(0, onAbortCalled)

            ship:abortCurrentOrder()
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("user", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Idle", ship:getOrder())
        end)
        it("fleet idles if there is no next order", function()
            local fleet = Fleet:new({CpuShip(), CpuShip(), CpuShip()})
            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil

            local order = Order:flyTo(1000, 0, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end
            })

            fleet:addOrder(order)
            assert.is_same("Fly towards", fleet:getLeader():getOrder())
            assert.is_same(0, onAbortCalled)

            fleet:abortCurrentOrder()
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("user", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Idle", fleet:getLeader():getOrder())
        end)
        it("carries out next order if there is one in the cue", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(1000, 0))
            ship:addOrder(Order:flyTo(2000, 0))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            ship:abortCurrentOrder()
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({2000, 0}, {ship:getOrderTargetLocation()})
        end)
        it("carries out next order without delay if there is one in the cue", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(1000, 0, {delayAfter = 10}))
            ship:addOrder(Order:flyTo(2000, 0))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            Cron.tick(1)

            ship:abortCurrentOrder()
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({2000, 0}, {ship:getOrderTargetLocation()})
        end)
        it("does nothing if there is no current order", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            ship:abortCurrentOrder()
        end)
    end)

    describe("flushOrders()", function()
        it("ship does not carry out any new orders after the one is completed", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(1000, 0))
            ship:addOrder(Order:flyTo(2000, 0))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            Cron.tick(1)
            ship:flushOrders()
            ship:setPosition(1000, 0)

            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})
        end)
        it("fleet does not carry out any new orders after the one is completed", function()
            local fleet = Fleet:new({CpuShip(), CpuShip(), CpuShip()})
            Fleet:withOrderQueue(fleet)
            fleet:getLeader():setPosition(0, 0)

            fleet:addOrder(Order:flyTo(1000, 0))
            fleet:addOrder(Order:flyTo(2000, 0))
            assert.is_same("Fly towards", fleet:getLeader():getOrder())
            assert.is_same({1000, 0}, {fleet:getLeader():getOrderTargetLocation()})

            Cron.tick(1)
            fleet:flushOrders()
            fleet:getLeader():setPosition(1000, 0)

            Cron.tick(1)
            assert.is_same("Fly towards", fleet:getLeader():getOrder())
            assert.is_same({1000, 0}, {fleet:getLeader():getOrderTargetLocation()})
        end)
        it("does nothing if there are no further orders", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            ship:abortCurrentOrder()
        end)
    end)

    describe("forceOrderNow()", function()
        it("executes a ship order immediately", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil

            local order = Order:flyTo(1000, 0, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end
            })
            ship:addOrder(order)
            ship:addOrder(Order:flyTo(2000, 0))
            ship:addOrder(Order:flyTo(3000, 0))
            ship:addOrder(Order:flyTo(4000, 0))

            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same(0, onAbortCalled)

            ship:forceOrderNow(Order:flyTo(0, 1000))
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("user", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 1000}, {ship:getOrderTargetLocation()})
        end)

        it("executes a fleet order immediately", function()
            local fleet = Fleet:new({CpuShip(), CpuShip(), CpuShip()})
            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil

            local order = Order:flyTo(1000, 0, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end
            })

            fleet:addOrder(order)
            fleet:addOrder(Order:flyTo(2000, 0))
            fleet:addOrder(Order:flyTo(3000, 0))
            fleet:addOrder(Order:flyTo(4000, 0))
            assert.is_same("Fly towards", fleet:getLeader():getOrder())
            assert.is_same(0, onAbortCalled)

            fleet:forceOrderNow(Order:flyTo(0, 1000))
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("user", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Fly towards", fleet:getLeader():getOrder())
            assert.is_same({0, 1000}, {fleet:getLeader():getOrderTargetLocation()})
        end)
        it("excutes the order if none was executed before", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            Cron.tick(1)

            ship:forceOrderNow(Order:flyTo(1000, 0))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})
        end)

        it("fails if parameter is not an order", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)
            ship:addOrder(Order:flyTo(1000, 0))
            ship:addOrder(Order:flyTo(2000, 0))
            ship:addOrder(Order:flyTo(3000, 0))
            ship:addOrder(Order:flyTo(4000, 0))

            assert.has_error(function()
                ship:forceOrderNow()
            end)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            ship:setPosition(1000, 0)
            Cron.tick(1)

            assert.has_error(function()
                ship:forceOrderNow(42)
            end)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({2000, 0}, {ship:getOrderTargetLocation()})

            ship:setPosition(2000, 0)
            Cron.tick(1)

            assert.has_error(function()
                ship:forceOrderNow(CpuShip())
            end)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({3000, 0}, {ship:getOrderTargetLocation()})

            ship:setPosition(3000, 0)
            Cron.tick(1)

            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({4000, 0}, {ship:getOrderTargetLocation()})
        end)
    end)

    describe("Order:tick()", function()
        it("executes the next order if Order:tick() returns false", function()
            local order = mockOrder()

            local called = 0
            order.getShipExecutor = function()
                return {
                    go = function(_, ship) ship:orderRoaming() end,
                    tick = function()
                        called = called + 1
                        if called > 3 then
                            return false, "boom"
                        end
                    end,
                }
            end

            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            ship:addOrder(order)
            ship:addOrder(Order:flyTo(1000, 0))
            assert.is_same("Roaming", ship:getOrder())

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
        end)
        it("makes the ship idle if Order:tick() returns false and there is no next order", function()
            local order = mockOrder()

            local called = 0
            order.getShipExecutor = function()
                return {
                    go = function(_, ship) ship:orderRoaming() end,
                    tick = function()
                        called = called + 1
                        if called > 3 then
                            return false, "boom"
                        end
                    end,
                }
            end

            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            ship:addOrder(order)
            assert.is_same("Roaming", ship:getOrder())

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same("Idle", ship:getOrder())

            ship:addOrder(Order:flyTo(1000, 0))
            assert.is_same("Fly towards", ship:getOrder())
        end)
    end)

    describe("delay", function()
        it("delays the execution of the next command", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            local onCompletionCalled = 0
            ship:addOrder(Order:flyTo(1000, 0, {
                onCompletion = function() onCompletionCalled = onCompletionCalled + 1 end,
                delayAfter = 10,
            }))
            ship:addOrder(Order:flyTo(0, 1000))

            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            assert.is_same(0, onCompletionCalled)
            ship:setPosition(1000, 0)
            Cron.tick(1)
            assert.is_same(1, onCompletionCalled)
            -- but the command should not have changed yet
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})
            for _=1,9 do Cron.tick(1) end
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 1000}, {ship:getOrderTargetLocation()})
        end)

        it("will be respected if addCommand is called during delay", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(0, 0, {
                delayAfter = 10,
            }))

            for _=1,5 do Cron.tick(1) end
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 0}, {ship:getOrderTargetLocation()})

            ship:addOrder(Order:flyTo(1000, 0))
            -- it should not change yet
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 0}, {ship:getOrderTargetLocation()})

            for _=1,4 do Cron.tick(1) end
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 0}, {ship:getOrderTargetLocation()})

            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})
        end)
    end)

    describe("loop", function()
        it("allows to loop orders", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(1000, 0, {
                onCompletion = function(self, ship) ship:addOrder(self) end,
            }))
            ship:addOrder(Order:flyTo(0, 0, {
                onCompletion = function(self, ship) ship:addOrder(self) end,
            }))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            ship:setPosition(1000, 0)
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 0}, {ship:getOrderTargetLocation()})

            ship:setPosition(0, 0)
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            ship:setPosition(1000, 0)
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 0}, {ship:getOrderTargetLocation()})

        end)
    end)

    describe("GM interaction", function()
        it("recovers after GM interaction", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(1000, 0))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            -- GM interferes
            ship:orderRoaming()
            Cron.tick(1)
            assert.is_same("Roaming", ship:getOrder())

            -- GM resets
            ship:orderIdle()
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})
        end)
        it("GM can carry out orders on behalf of the ship", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)
            ship:setPosition(0, 0)

            ship:addOrder(Order:flyTo(1000, 0))
            ship:addOrder(Order:flyTo(0, 0))
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({1000, 0}, {ship:getOrderTargetLocation()})

            -- GM interferes
            ship:orderRoaming()
            Cron.tick(1)
            assert.is_same("Roaming", ship:getOrder())

            -- ship passes by accident :)
            ship:setPosition(1000, 0)
            Cron.tick(1)
            assert.is_same("Fly towards", ship:getOrder())
            assert.is_same({0, 0}, {ship:getOrderTargetLocation()})
        end)
    end)
end)