insulate("Ship:withEvents", function()
    require "lively_epsilon"
    require "test.mocks"

    it("fails if a number is given instead of ship", function()
        assert.has_error(function()
            Ship:withEvents(42)
        end)
    end)

    it("includes events from ShipTemplateBased", function()
        -- just test onDestruction
        local called = 0
        local ship = eeCpuShipMock()
        Ship:withEvents(ship, {
            onDestruction = function()
                called = called + 1
            end,
        })

        Cron.tick(1)
        assert.is_same(0, called)

        ship:destroy()
        Cron.tick(1)
        assert.is_same(1, called)
    end)

    describe("onDocking", function()
        it("is called when the ship docks a station", function()
            local called = 0
            local station = eeStationMock()
            local ship = eeCpuShipMock()
            Ship:withEvents(ship, {
                onDocking = function()
                    called = called + 1
                end,
            })

            Cron.tick(1)
            assert.is_same(0, called)

            ship:orderDock(station)
            Cron.tick(1)
            assert.is_same(0, called)

            ship:setDockedAt(station)
            Cron.tick(1)
            assert.is_same(1, called)

            -- it is only called once
            Cron.tick(1)
            assert.is_same(1, called)

            ship:orderIdle()
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(1, called)

            ship:orderDock(station)
            Cron.tick(1)
            assert.is_same(1, called)

            -- it triggers again when undocked in between
            ship:setDockedAt(station)
            Cron.tick(1)
            assert.is_same(2, called)
        end)

        it("is called when ship docks multiple stations", function()
            local called = 0
            local station1 = eeStationMock()
            local station2 = eeStationMock()
            local ship = eeCpuShipMock()
            local calledArg1, calledArg2
            Ship:withEvents(ship, {
                onDocking = function(arg1, arg2)
                    called = called + 1
                    calledArg1, calledArg2 = arg1, arg2
                end,
            })

            Cron.tick(1)
            assert.is_same(0, called)

            ship:orderDock(station1)
            Cron.tick(1)
            assert.is_same(0, called)

            ship:setDockedAt(station1)
            Cron.tick(1)
            assert.is_same(1, called)
            assert.is_same(calledArg1, ship)
            assert.is_same(calledArg2, station1)

            ship:orderDock(station2)
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(1, called)

            ship:setDockedAt(station2)
            Cron.tick(1)
            assert.is_same(2, called)
            assert.is_same(calledArg1, ship)
            assert.is_same(calledArg2, station2)

            ship:orderDock(station1)
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(2, called)

            ship:setDockedAt(station1)
            Cron.tick(1)
            assert.is_same(3, called)
        end)

        it("does not fail if the callback errors", function()
            local station = eeStationMock()
            local ship = eeCpuShipMock()
            Ship:withEvents(ship, {
                onDocking = function()
                    error("Boom")
                end,
            })

            ship:orderDock(station)
            ship:setDockedAt(station)

            assert.not_has_error(function()
                Cron.tick(1)
            end)
        end)

        it("fails if onDocking is not a callback", function()
            local ship = eeCpuShipMock()

            assert.has_error(function()
                Ship:withEvents(ship, { onDocking = 42})
            end)
        end)
    end)

    describe("onUndocking", function()
        it("is called when the ship undocks a station", function()
            local called = 0
            local station = eeStationMock()
            local ship = eeCpuShipMock()
            Ship:withEvents(ship, {
                onUndocking = function()
                    called = called + 1
                end,
            })

            Cron.tick(1)
            assert.is_same(0, called)

            ship:orderDock(station)
            ship:setDockedAt(station)
            Cron.tick(1)
            assert.is_same(0, called)

            ship:orderIdle()
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(1, called)

            -- it is only called once
            Cron.tick(1)
            assert.is_same(1, called)

            ship:orderDock(station)
            ship:setDockedAt(station)
            Cron.tick(1)
            assert.is_same(1, called)

            -- it triggers again
            ship:orderIdle()
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(2, called)
        end)

        it("is called when ship undocks multiple stations", function()
            local called = 0
            local station1 = eeStationMock()
            local station2 = eeStationMock()
            local ship = eeCpuShipMock()
            local calledArg1, calledArg2
            Ship:withEvents(ship, {
                onUndocking = function(arg1, arg2)
                    called = called + 1
                    calledArg1, calledArg2 = arg1, arg2
                end,
            })

            Cron.tick(1)
            assert.is_same(0, called)

            ship:orderDock(station1)
            Cron.tick(1)
            assert.is_same(0, called)

            ship:setDockedAt(station1)
            Cron.tick(1)
            assert.is_same(0, called)

            ship:orderDock(station2)
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(1, called)
            assert.is_same(calledArg1, ship)
            assert.is_same(calledArg2, station1)

            ship:setDockedAt(station2)
            Cron.tick(1)
            assert.is_same(1, called)

            ship:orderDock(station1)
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(2, called)
            assert.is_same(calledArg1, ship)
            assert.is_same(calledArg2, station2)

            ship:setDockedAt(station1)
            Cron.tick(1)
            assert.is_same(2, called)

            ship:orderDock(station2)
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(3, called)
            assert.is_same(calledArg1, ship)
            assert.is_same(calledArg2, station1)
        end)

        it("does not fail if the callback errors", function()
            local station = eeStationMock()
            local ship = eeCpuShipMock()
            Ship:withEvents(ship, {
                onUndocking = function()
                    error("Boom")
                end,
            })

            ship:orderDock(station)
            ship:setDockedAt(station)
            Cron.tick(1)
            ship:orderIdle()
            ship:setDockedAt(nil)

            assert.not_has_error(function()
                Cron.tick(1)
            end)
        end)

        it("fails if onUndocking is not a callback", function()
            local ship = eeCpuShipMock()

            assert.has_error(function()
                Ship:withEvents(ship, { onUndocking = 42})
            end)
        end)
    end)


    describe("onDockInitiation", function()
        it("is called when the ship approaches a station with the intention of docking", function()
            local called = 0
            local station = eeStationMock()
            local ship = eeCpuShipMock()
            local calledArg1, calledArg2
            Ship:withEvents(ship, {
                onDockInitiation = function(arg1, arg2)
                    called = called + 1
                    calledArg1 = arg1
                    calledArg2 = arg2
                end,
            })
            station:setPosition(0, 0)
            ship:setPosition(10000, 0)
            ship:orderDock(station)

            Cron.tick(1)
            assert.is_same(0, called)

            ship:setPosition(2000, 0)
            Cron.tick(1)
            assert.is_same(1, called)
            assert.is_same(ship, calledArg1)
            assert.is_same(station, calledArg2)

            -- it is not called multiple times
            Cron.tick(1)
            assert.is_same(1, called)

            -- it resets after a ship was docked at a station
            ship:setDockedAt(station)
            Cron.tick(1)
            assert.is_same(1, called)

            ship:orderIdle()
            ship:setDockedAt(nil)
            Cron.tick(1)
            assert.is_same(1, called)

            ship:orderDock(station)
            Cron.tick(1)
            assert.is_same(2, called)
        end)

        it("resets when ship changes orders", function()
            local called = 0
            local station = eeStationMock()
            local ship = eeCpuShipMock()
            local calledArg1, calledArg2
            Ship:withEvents(ship, {
                onDockInitiation = function(arg1, arg2)
                    called = called + 1
                    calledArg1 = arg1
                    calledArg2 = arg2
                end,
            })
            station:setPosition(0, 0)
            ship:setPosition(10000, 0)
            ship:orderDock(station)

            Cron.tick(1)
            assert.is_same(0, called)

            ship:setPosition(2000, 0)
            Cron.tick(1)
            assert.is_same(1, called)

            ship:orderIdle()
            Cron.tick(1)
            assert.is_same(1, called)

            ship:orderDock(station)
            Cron.tick(1)
            assert.is_same(2, called)
        end)

        it("is called when ship can not decide between two stations", function()
            local called = 0
            local station1 = eeStationMock()
            local station2 = eeStationMock()
            local ship = eeCpuShipMock()
            local calledArg1, calledArg2
            Ship:withEvents(ship, {
                onDockInitiation = function(arg1, arg2)
                    called = called + 1
                    calledArg1 = arg1
                    calledArg2 = arg2
                end,
            })
            station1:setPosition(0, 0)
            ship:setPosition(2000, 0)
            station2:setPosition(4000, 0)

            ship:orderDock(station1)
            Cron.tick(1)
            assert.is_same(1, called)
            assert.is_same(ship, calledArg1)
            assert.is_same(station1, calledArg2)

            ship:orderDock(station2)
            Cron.tick(1)
            assert.is_same(2, called)
            assert.is_same(ship, calledArg1)
            assert.is_same(station2, calledArg2)

            ship:orderDock(station1)
            Cron.tick(1)
            assert.is_same(3, called)
            assert.is_same(ship, calledArg1)
            assert.is_same(station1, calledArg2)
        end)

        it("does not fail if the callback errors", function()
            local station = eeStationMock()
            local ship = eeCpuShipMock()
            Ship:withEvents(ship, {
                onDockInitiation = function()
                    error("Boom")
                end,
            })
            station:setPosition(0, 0)
            ship:setPosition(2000, 0)
            ship:orderDock(station)

            assert.not_has_error(function()
                Cron.tick(1)
            end)
        end)

        it("fails if onDockInitiation is not a callback", function()
            local ship = eeCpuShipMock()

            assert.has_error(function()
                Ship:withEvents(ship, { onDockInitiation = 42})
            end)
        end)
    end)
end)