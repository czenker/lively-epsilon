insulate("Order", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"
    require "test.orders.helper"

    describe("dock()", function()
        testSignature(Order.dock, {SpaceStation()}, it, assert)
        testHappyShipCase(Order.dock, function()
            local station = SpaceStation()
            return {
                args = { station },
                setUp = function() end,
                assertOrder = "Dock",
                assertOrderTarget = station,
                assertOrderTargetLocation = nil,
                complete = function(ship)
                    ship:setDockedAt(station)
                end,
            }
        end, it, assert)
        testHappyFleetCase(Order.dock, function()
            local station = SpaceStation()
            return {
                args = { station },
                setUp = function() end,
                assertOrder = "Dock",
                assertOrderTarget = station,
                assertOrderTargetLocation = nil,
                complete = function(fleet)
                    for _, ship in pairs(fleet:getShips()) do ship:setDockedAt(station) end
                end,
            }
        end, it, assert)

        it("fails if station is an enemy for ship", function()
            local ship = CpuShip():setFactionId(1)
            local station = SpaceStation():setFactionId(2)

            Ship:withOrderQueue(ship)

            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:dock(station, {
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
            assert.is_same("enemy_station", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Idle", ship:getOrder())
        end)
        it("fails if station is an enemy for fleet", function()
            local fleet = Fleet:new({
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
            })
            local station = SpaceStation():setFactionId(2)

            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:dock(station, {
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
            assert.is_same("enemy_station", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Idle", fleet:getLeader():getOrder())
        end)
        it("fails if station turns into an enemy for ship", function()
            local ship = CpuShip():setFactionId(1)
            local station = SpaceStation():setFactionId(0)

            Ship:withOrderQueue(ship)

            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:dock(station, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            ship:addOrder(order)

            Cron.tick(1)
            assert.is_same("Dock", ship:getOrder())

            station:setFactionId(2)
            Cron.tick(1)
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("enemy_station", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Idle", ship:getOrder())
        end)
        it("fails if station turns into an enemy for fleet", function()
            local fleet = Fleet:new({
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
                CpuShip():setFactionId(1),
            })
            local station = SpaceStation():setFactionId(0)

            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:dock(station, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            fleet:addOrder(order)

            Cron.tick(1)
            assert.is_same("Dock", fleet:getLeader():getOrder())

            station:setFactionId(2)
            Cron.tick(1)
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("enemy_station", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Idle", fleet:getLeader():getOrder())
        end)
        it("fails if station is destroyed for ship", function()
            local ship = CpuShip()
            local station = SpaceStation()

            Ship:withOrderQueue(ship)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:dock(station, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            ship:addOrder(order)

            Cron.tick(1)
            assert.is_same("Dock", ship:getOrder())

            station:destroy()

            Cron.tick(1)
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("invalid_station", abortArg2)
            assert.is_same(ship, abortArg3)
            assert.is_same("Idle", ship:getOrder())
        end)
        it("fails if station is destroyed for fleet", function()
            local fleet = Fleet:new({CpuShip(), CpuShip(), CpuShip()})
            local station = SpaceStation()

            Fleet:withOrderQueue(fleet)
            local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
            local order = Order:dock(station, {
                onAbort = function(arg1, arg2, arg3)
                    onAbortCalled = onAbortCalled + 1
                    abortArg1 = arg1
                    abortArg2 = arg2
                    abortArg3 = arg3
                end,
            })
            fleet:addOrder(order)

            Cron.tick(1)
            assert.is_same("Dock", fleet:getLeader():getOrder())

            station:destroy()

            Cron.tick(1)
            assert.is_same(1, onAbortCalled)
            assert.is_same(order, abortArg1)
            assert.is_same("invalid_station", abortArg2)
            assert.is_same(fleet, abortArg3)
            assert.is_same("Idle", fleet:getLeader():getOrder())
        end)
        it("repairs a docked ship if the station is friendly and supports it", function()
            local ship = CpuShip():setHullMax(100):setHull(50)

            local station = SpaceStation()
            station:setRepairDocked(true)

            Ship:withOrderQueue(ship)
            local completed = false
            ship:addOrder(Order:dock(station, {
                onCompletion = function() completed = true end,
            }))

            -- ship not docked
            Cron.tick(1)
            assert.is_false(completed)

            -- ship docked but unrepaired
            ship:setDockedAt(station)
            Cron.tick(1)
            assert.is_false(completed)

            -- ship docked and repaired
            ship:setHull(100)
            Cron.tick(1)
            assert.is_true(completed)
        end)

        it("waits for missiles to be refilled", function()
            local ship = CpuShip():setWeaponStorageMax("homing", 8):setWeaponStorage("homing", 0)

            local station = SpaceStation()

            Ship:withOrderQueue(ship)
            local completed = false
            ship:addOrder(Order:dock(station, {
                onCompletion = function() completed = true end,
            }))

            -- ship not docked
            Cron.tick(1)
            assert.is_false(completed)

            -- ship docked but no missiles
            ship:setDockedAt(station)
            Cron.tick(1)
            assert.is_false(completed)

            -- ship docked and refilled
            ship:setWeaponStorage("homing", 8)
            Cron.tick(1)
            assert.is_true(completed)
        end)

        it("waits for shields to recharge", function()
            local ship = CpuShip():setShieldsMax(100, 50, 10):setShields(20, 50, 0)

            local station = SpaceStation()

            Ship:withOrderQueue(ship)
            local completed = false
            ship:addOrder(Order:dock(station, {
                onCompletion = function() completed = true end,
            }))

            -- ship not docked
            Cron.tick(1)
            assert.is_false(completed)

            -- ship docked but low shields
            ship:setDockedAt(station)
            Cron.tick(1)
            assert.is_false(completed)

            -- ship docked and shields loaded
            ship:setShields(100, 50, 10)
            Cron.tick(1)
            assert.is_true(completed)
        end)
        it("repairs a docked fleet if the station is friendly and supports it", function()
            local ship1 = CpuShip():setHullMax(100):setHull(50)
            local ship2 = CpuShip():setHullMax(100):setHull(50)
            local ship3 = CpuShip():setHullMax(100):setHull(50)
            local fleet = Fleet:new({ship1, ship2, ship3})

            local station = SpaceStation()
            station:setRepairDocked(true)

            Fleet:withOrderQueue(fleet)
            local completed = false
            fleet:addOrder(Order:dock(station, {
                onCompletion = function() completed = true end,
            }))
            fleet:addOrder(Order:flyTo(1000, 0))

            -- fleet leader not docked
            Cron.tick(1)
            assert.is_false(completed)
            assert.is_same("Dock", ship1:getOrder())
            assert.is_same("Fly in formation", ship2:getOrder())
            assert.is_same("Fly in formation", ship3:getOrder())

            -- fleet leader docked, fleet leader unrepaired
            ship1:setDockedAt(station)
            Cron.tick(1)
            assert.is_false(completed)
            assert.is_same("Dock", ship1:getOrder())
            assert.is_same("Dock", ship2:getOrder())
            assert.is_same(station, ship2:getOrderTarget())
            assert.is_same("Dock", ship3:getOrder())
            assert.is_same(station, ship3:getOrderTarget())

            -- fleet leader docked, fleet leader repaired, wingmen not docked
            ship1:setHull(100)
            Cron.tick(1)
            assert.is_false(completed)
            assert.is_same("Dock", ship1:getOrder())
            assert.is_same("Dock", ship2:getOrder())
            assert.is_same("Dock", ship3:getOrder())

            -- fleet leader repaired, wingmen docked
            ship2:setDockedAt(station)
            ship3:setDockedAt(station)
            Cron.tick(1)
            assert.is_false(completed)

            -- fleet leader repaired, wingmen repaired
            ship2:setHull(100)
            ship3:setHull(100)
            Cron.tick(1)
            assert.is_true(completed)

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)

            assert.is_same("Fly towards", ship1:getOrder())
            assert.is_same("Fly in formation", ship2:getOrder())
            assert.is_same("Fly in formation", ship3:getOrder())
        end)
        it("waits for all ships to be repaired, refilled and recharged", function()
            local ship1 = CpuShip()
            local ship2 = CpuShip():setHullMax(100):setHull(50) -- damaged
            local ship3 = CpuShip():setWeaponStorageMax("homing", 8):setWeaponStorage("homing", 0) -- weapons
            local ship4 = CpuShip():setShieldsMax(100, 50, 10):setShields(20, 50, 0) -- broken shields
            local fleet = Fleet:new({ship1, ship2, ship3, ship4})

            local station = SpaceStation()
            station:setRepairDocked(true)

            Fleet:withOrderQueue(fleet)
            local completed = false
            fleet:addOrder(Order:dock(station, {
                onCompletion = function() completed = true end,
            }))
            fleet:addOrder(Order:flyTo(1000, 0))

            ship1:setDockedAt(station)
            ship2:setDockedAt(station)
            ship3:setDockedAt(station)
            ship4:setDockedAt(station)

            assert.is_false(completed)

            -- repair ship
            ship2:setHull(100)
            Cron.tick(1)
            Cron.tick(1) --twice for Fleet's cron to catch up
            assert.is_false(completed)
            assert.is_same("Fly in formation", ship2:getOrder())

            -- refill missiles
            ship3:setWeaponStorage("homing", 8)
            Cron.tick(1)
            Cron.tick(1) --twice for Fleet's cron to catch up
            assert.is_false(completed)
            assert.is_same("Fly in formation", ship3:getOrder())

            -- recharge shields
            ship4:setShields(100, 50, 10)
            Cron.tick(1)
            Cron.tick(1) --twice for Fleet's cron to catch up
            assert.is_true(completed)
            assert.is_same("Fly in formation", ship4:getOrder())
        end)
        it("undocks all fleet ships if the order is aborted", function()
            local ship1 = CpuShip():setHullMax(100):setHull(50)
            local ship2 = CpuShip():setHullMax(100):setHull(50)
            local ship3 = CpuShip():setHullMax(100):setHull(50)
            local fleet = Fleet:new({ship1, ship2, ship3})

            local station = SpaceStation()
            station:setRepairDocked(true)

            Fleet:withOrderQueue(fleet)
            fleet:addOrder(Order:dock(station))

            -- fleet leader docked, fleet leader unrepaired
            ship1:setDockedAt(station)
            Cron.tick(1)
            assert.is_same("Dock", ship1:getOrder())
            assert.is_same("Dock", ship2:getOrder())
            assert.is_same("Dock", ship3:getOrder())

            fleet:abortCurrentOrder()
            Cron.tick(1)

            assert.is_same("Idle", ship1:getOrder())
            assert.is_same("Fly in formation", ship2:getOrder())
            assert.is_same("Fly in formation", ship3:getOrder())
        end)

        it("fails if no station is given", function()
            assert.has_error(function()
                Order:dock(nil)
            end)
            assert.has_error(function()
                Order:dock("foo")
            end)
            assert.has_error(function()
                Order:dock(CpuShip())
            end)
        end)
    end)
end)