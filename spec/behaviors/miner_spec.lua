insulate("Ship:behaveAsMiner()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"
    require "spec.log_catcher"

    local product = Product:new("Red Herring", {id = "red-herring"})
    local mockValidStation = function()
        local station = SpaceStation()
        Station:withStorageRooms(station, {
            [product] = 999,
        })

        return station
    end

    local mockValidMiner = function()
        local miner = CpuShip()
        Ship:withStorageRooms(miner, {
            [product] = 999,
        })
        miner.getBeamWeaponRange = function() return 500 end

        return miner
    end

    it("does basically work :)", function()
        withUniverse(function()
            local station = mockValidStation()
            local miner = mockValidMiner()
            local asteroid = Asteroid()

            station:setPosition(0, 0)
            miner:setPosition(0, 0)
            asteroid:setPosition(1000, 0)

            local whenMinedCalled = 0
            local asteroidMinedCalled = 0
            local asteroidMinedArg1, asteroidMinedArg2, asteroidMinedArg3
            local headingAsteroidCalled = 0
            local headingAsteroidArg1, headingAsteroidArg2
            local unloadedCalled = 0
            local unloadedArg1, unloadedArg2, unloadedArg3
            local headingHomeCalled = 0
            local headingHomeArg1, headingHomeArg2, headingHomeArg3
            Ship:behaveAsMiner(miner, station, function()
                whenMinedCalled = whenMinedCalled + 1
                return {
                    [product] = 42,
                }
            end, {
                onHeadingAsteroid = function(arg1, arg2)
                    headingAsteroidCalled = headingAsteroidCalled + 1
                    headingAsteroidArg1, headingAsteroidArg2 = arg1, arg2
                end,
                onAsteroidMined = function(arg1, arg2, arg3)
                    asteroidMinedCalled = asteroidMinedCalled + 1
                    asteroidMinedArg1, asteroidMinedArg2, asteroidMinedArg3 = arg1, arg2, arg3
                end,
                onHeadingHome = function(arg1, arg2, arg3)
                    headingHomeCalled = headingHomeCalled + 1
                    headingHomeArg1, headingHomeArg2, headingHomeArg3 = arg1, arg2, arg3
                end,
                onUnloaded = function(arg1, arg2, arg3)
                    unloadedCalled = unloadedCalled + 1
                    unloadedArg1, unloadedArg2, unloadedArg3 = arg1, arg2, arg3
                end,
            })

            -- find a close asteroid
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid, miner:getOrderTarget())
            assert.is_same("asteroid", miner:getMinerState())
            assert.is_same(1, headingAsteroidCalled)
            assert.is_same(miner, headingAsteroidArg1)
            assert.is_same(asteroid, headingAsteroidArg2)

            miner:setPosition(100, 0)
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid, miner:getOrderTarget())

            miner:setPosition(200, 0)
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid, miner:getOrderTarget())

            -- now it is close and should start mining
            miner:setPosition(800, 0)
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid, miner:getOrderTarget())
            assert.is_same("mining", miner:getMinerState())

            -- ...let it mine a little...
            for i=1,14 do Cron.tick(1) end
            assert.is_same(0, whenMinedCalled)
            assert.is_same(0, asteroidMinedCalled)
            assert.is_same(0, headingHomeCalled)
            assert.is_same("mining", miner:getMinerState())

            -- now the mining should have finished
            Cron.tick(1)
            assert.is_same(1, whenMinedCalled)
            assert.is_same(42, miner:getProductStorage(product))
            assert.is_same(1, asteroidMinedCalled)
            assert.is_same(miner, asteroidMinedArg1)
            assert.is_same(asteroid, asteroidMinedArg2)
            assert.is_same("table", type(asteroidMinedArg3))
            assert.is_same(42, asteroidMinedArg3[product])

            assert.is_same(1, headingHomeCalled)
            assert.is_same(miner, headingHomeArg1)
            assert.is_same(station, headingHomeArg2)
            assert.is_same("table", type(headingHomeArg3))
            assert.is_same(42, headingHomeArg3[product])

            assert.is_same("Dock", miner:getOrder())
            assert.is_same(station, miner:getOrderTarget())
            assert.is_same("home", miner:getMinerState())

            miner:setPosition(200, 0)
            Cron.tick(1)
            assert.is_same("Dock", miner:getOrder())
            assert.is_same(station, miner:getOrderTarget())
            assert.is_same("home", miner:getMinerState())

            miner:setPosition(0, 0)
            miner:setDockedAt(station)
            Cron.tick(1)
            assert.is_same("Dock", miner:getOrder())
            assert.is_same(station, miner:getOrderTarget())
            assert.is_same("unloading", miner:getMinerState())

            -- ...let it unload a little...
            for i=1,14 do Cron.tick(1) end
            assert.is_same("Dock", miner:getOrder())
            assert.is_same(station, miner:getOrderTarget())
            assert.is_same(42, miner:getProductStorage(product))
            assert.is_same(0, station:getProductStorage(product))
            assert.is_same("unloading", miner:getMinerState())
            assert.is_same(0, unloadedCalled)

            -- ...now delivery should be complete
            Cron.tick(1)
            assert.is_same(0, miner:getProductStorage(product))
            assert.is_same(42, station:getProductStorage(product))
            assert.is_same(1, unloadedCalled)
            assert.is_same(miner, unloadedArg1)
            assert.is_same(station, unloadedArg2)
            assert.is_same("table", type(unloadedArg3))
            assert.is_same(42, unloadedArg3[product])

            -- cycle starts again
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid, miner:getOrderTarget())
            assert.is_same("asteroid", miner:getMinerState())
        end)
    end)

    it("does not mine more asteroids when a maximum time has run out", function()
        withUniverse(function()
            local station = mockValidStation()
            local miner = mockValidMiner()
            local asteroid1 = Asteroid()

            station:setPosition(0, 0)
            miner:setPosition(0, 0)
            asteroid1:setPosition(1000, 0)

            local whenMinedCalled = 0
            Ship:behaveAsMiner(miner, station, function()
                whenMinedCalled = whenMinedCalled + 1
                return {
                    [product] = 42,
                }
            end)

            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid1, miner:getOrderTarget())

            for i=1,999 do Cron.tick(1) end

            local asteroid2 = Asteroid()
            asteroid2:setPosition(2000, 0)

            -- it cares out its order first
            miner:setPosition(asteroid1:getPosition())
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid1, miner:getOrderTarget())
            for i=1,15 do Cron.tick(1) end
            assert.is_same("Dock", miner:getOrder())
            assert.is_same(station, miner:getOrderTarget())
        end)
    end)

    it("warns when there are no mineable asteroids around the station", function()
        withUniverse(function() withLogCatcher(function(logs)
            local station = mockValidStation():setCallSign("Home")
            local miner = mockValidMiner():setCallSign("Dummy")
            local asteroid = Asteroid()

            station:setPosition(0, 0)
            miner:setPosition(0, 0)
            miner:setDockedAt(station)
            asteroid:setPosition(99999, 0)

            local whenMinedCalled = 0
            Ship:behaveAsMiner(miner, station, function()
                whenMinedCalled = whenMinedCalled + 1
                return {
                    [product] = 42,
                }
            end)

            assert.is_same(1, logs:countWarnings())
            assert.is_same("unknown", miner:getMinerState())
            assert.is_same("Dummy did not find any mineable asteroids around Home", logs:popLastWarning())
            assert.is_same(nil, logs:popLastWarning()) -- no further errors

            Cron.tick(1)
            assert.is_same(nil, logs:popLastWarning()) -- it does not spam

            -- but it starts as soon as an asteroid is close enough
            asteroid:setPosition(1000, 0)
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid, miner:getOrderTarget())
            assert.is_same("asteroid", miner:getMinerState())
        end) end)
    end)

    it("idles when home base is destroyed", function()
        withUniverse(function() withLogCatcher(function(logs)
            local station = mockValidStation():setCallSign("Home")
            local miner = mockValidMiner():setCallSign("Dummy")
            local asteroid = Asteroid()

            station:setPosition(0, 0)
            miner:setPosition(0, 0)
            miner:setDockedAt(station)
            asteroid:setPosition(1000, 0)

            Ship:behaveAsMiner(miner, station, function()
                return {
                    [product] = 42,
                }
            end)

            Cron.tick(1)
            assert.is_same("asteroid", miner:getMinerState())

            station:destroy()
            Cron.tick(1)
            assert.is_same(1, logs:countWarnings())
            assert.is_same("unknown", miner:getMinerState())
            assert.is_same("Dummy has lost its home base. :(", logs:popLastWarning())
            assert.is_same(nil, logs:popLastWarning()) -- no further errors

            Cron.tick(1)
            assert.is_same(nil, logs:popLastWarning()) -- it does not spam

        end) end)
    end)

    it("selects a new asteroid if the current target is destroyed", function()
        withUniverse(function(logs)
            local station = mockValidStation():setCallSign("Home")
            local miner = mockValidMiner():setCallSign("Dummy")
            local asteroid1 = Asteroid():setCallSign("one")
            local asteroid2 = Asteroid():setCallSign("two")

            station:setPosition(0, 0)
            miner:setPosition(0, 0)
            miner:setDockedAt(station)
            asteroid1:setPosition(1000, 0)
            asteroid2:setPosition(2000, 0)

            Ship:behaveAsMiner(miner, station, function()
                return {
                    [product] = 42,
                }
            end)

            Cron.tick(1)
            assert.is_same("asteroid", miner:getMinerState())
            assert.is_same("Attack", miner:getOrder())

            local target = miner:getOrderTarget()

            target:destroy()
            Cron.tick(1)
            assert.is_same("asteroid", miner:getMinerState())
            assert.is_same("Attack", miner:getOrder())
            assert.not_is_same(target, miner:getOrderTarget())
        end)
    end)

    it("selects a new asteroid if the current target is destroyed while mining", function()
        withUniverse(function(logs)
            local station = mockValidStation():setCallSign("Home")
            local miner = mockValidMiner():setCallSign("Dummy")
            local asteroid1 = Asteroid():setCallSign("one")
            local asteroid2 = Asteroid():setCallSign("two")

            station:setPosition(100, 0)
            miner:setPosition(0, 100)
            miner:setDockedAt(station)
            asteroid1:setPosition(0, 0)
            asteroid2:setPosition(0, 500)

            Ship:behaveAsMiner(miner, station, function()
                return {
                    [product] = 42,
                }
            end)

            Cron.tick(1)
            assert.is_same("mining", miner:getMinerState())
            assert.is_same("Attack", miner:getOrder())

            local target = miner:getOrderTarget()

            target:destroy()
            Cron.tick(1)
            assert.is_same("asteroid", miner:getMinerState())
            assert.is_same("Attack", miner:getOrder())
            assert.not_is_same(target, miner:getOrderTarget())
        end)
    end)
    it("GM can change the mined asteroid", function()
        withUniverse(function()

            local station = mockValidStation()
            local miner = mockValidMiner()
            local asteroid1 = Asteroid()
            local asteroid2 = Asteroid()

            station:setPosition(0, 0)
            miner:setPosition(0, 0)
            miner:setDockedAt(station)
            asteroid1:setPosition(1000, 0)
            asteroid2:setPosition(99999, 0)

            local whenMinedCalled = 0
            Ship:behaveAsMiner(miner, station, function()
                whenMinedCalled = whenMinedCalled + 1
                return {
                    [product] = 42,
                }
            end)

            -- find a close asteroid
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid1, miner:getOrderTarget())
            assert.is_same("asteroid", miner:getMinerState())

            -- now it is close and should start mining
            miner:setPosition(800, 0)
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid1, miner:getOrderTarget())
            assert.is_same("mining", miner:getMinerState())

            -- it should spend some time mining, but not finish
            for i=1,10 do Cron.tick(1) end
            assert.is_same(0, whenMinedCalled)
            assert.is_same("mining", miner:getMinerState())

            -- now the GM interjects
            miner:orderFlyTowardsBlind(asteroid2:getPosition()) -- GM interface does not allow to issue Attack orders on asteroids
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid2, miner:getOrderTarget())
            assert.is_same("asteroid", miner:getMinerState())

            -- now it is close and should start mining
            miner:setPosition(asteroid2:getPosition())
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid2, miner:getOrderTarget())
            assert.is_same("mining", miner:getMinerState())

            -- it should spend the whole time mining
            for i=1,14 do Cron.tick(1) end
            assert.is_same(0, whenMinedCalled)
            assert.is_same("mining", miner:getMinerState())

            -- now the mining should have finished
            Cron.tick(1)
            assert.is_same(1, whenMinedCalled)
            assert.is_same(42, miner:getProductStorage(product))
            assert.is_same("Dock", miner:getOrder())
            assert.is_same(station, miner:getOrderTarget())
            assert.is_same("home", miner:getMinerState())

        end)
    end)

    it("GM can issue custom orders and reset them using the Idle order", function()
        withUniverse(function()
            local station = mockValidStation()
            local otherStation = SpaceStation()
            local miner = mockValidMiner()
            local asteroid = Asteroid()

            station:setPosition(0, 0)
            miner:setPosition(0, 0)
            miner:setDockedAt(station)
            asteroid:setPosition(1000, 0)

            local whenMinedCalled = 0
            Ship:behaveAsMiner(miner, station, function()
                whenMinedCalled = whenMinedCalled + 1
                return {
                    [product] = 42,
                }
            end)


            -- find a close asteroid
            Cron.tick(1)
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid, miner:getOrderTarget())
            assert.is_same("asteroid", miner:getMinerState())

            -- GM interjects
            miner:orderRoaming()
            for i=1,15 do
                Cron.tick(1)
                assert.is_same("unknown", miner:getMinerState())
            end

            -- GM resets the order
            miner:orderIdle()
            for i=1,15 do
                Cron.tick(1)
                assert.is_same("Attack", miner:getOrder())
                assert.is_same(asteroid, miner:getOrderTarget())
                assert.is_same("asteroid", miner:getMinerState())
            end

            -- GM interjects
            miner:orderDock(otherStation)
            for i=1,15 do
                Cron.tick(1)
                assert.is_same("unknown", miner:getMinerState())
            end

            -- GM resets the order
            miner:orderIdle()
            for i=1,15 do
                Cron.tick(1)
                assert.is_same("Attack", miner:getOrder())
                assert.is_same(asteroid, miner:getOrderTarget())
                assert.is_same("asteroid", miner:getMinerState())
            end
        end)
    end)

    it("GM can force a miner to go home", function()
        withUniverse(function()
            local station = mockValidStation()
            local miner = mockValidMiner()
            local asteroid = Asteroid()

            station:setPosition(0, 0)
            miner:setPosition(1000, 0)
            asteroid:setPosition(1000, 0)

            local headingHomeCalled = 0
            Ship:behaveAsMiner(miner, station, function()
                return { [product] = 42, }
            end, {
                onHeadingHome = function()
                    headingHomeCalled = headingHomeCalled + 1
                end
            })

            local asteroid2 = Asteroid()
            asteroid2:setPosition(2000, 0)

            for i=1,20 do Cron.tick(1) end
            assert.is_same("Attack", miner:getOrder())
            assert.is_same(asteroid2, miner:getOrderTarget())

            miner:orderDock(station)
            Cron.tick(1)
            assert.is_same(1, headingHomeCalled)

            -- ...GM rethinks...
            miner:orderIdle()
            Cron.tick(1)
            assert.is_same("asteroid", miner:getMinerState())

            -- ...but then orders miner home again...
            miner:orderDock(station)
            Cron.tick(1)
            assert.is_same(2, headingHomeCalled)

            miner:setPosition(station:getPosition())
            miner:setDockedAt(station)
            for i=1,20 do Cron.tick(1) end

            assert.is_same(0, miner:getProductStorage(product))
            assert.is_same(42, station:getProductStorage(product))
            -- ...miner goes on as usual after unloading
            assert.is_same("Attack", miner:getOrder())
        end)
    end)

    it("fails if ship is not a ship", function()
        local station = mockValidStation()
        assert.has_error(function()
            Ship:behaveAsMiner(nil, station, function() end)
        end, "Expected ship to be a CpuShip, but got <nil>")
        assert.has_error(function()
            Ship:behaveAsMiner(42, station, function() end)
        end, "Expected ship to be a CpuShip, but got <number>42")
        assert.has_error(function()
            Ship:behaveAsMiner(SpaceStation():setCallSign("Test"), station, function() end)
        end, "Expected ship to be a CpuShip, but got <SpaceStation>\"Test\"")
        assert.has_error(function()
            Ship:behaveAsMiner(SpaceShip():setCallSign("Test"), station, function() end)
        end, "Expected ship to be a CpuShip, but got <SpaceShip>\"Test\"")
    end)
    it("fails if ship is destroyed", function()
        local station = mockValidStation()
        local miner = mockValidMiner()
        miner:destroy()

        assert.has_error(function()
            Ship:behaveAsMiner(miner, station, function() end)
        end, "Expected ship to be a valid CpuShip, but got a destroyed one")
    end)
    it("fails if ship does not have storage", function()
        local station = mockValidStation()
        local miner = CpuShip():setCallSign("Dummy")

        assert.has_error(function()
            Ship:behaveAsMiner(miner, station, function() end)
        end, "Ship Dummy needs to have storage configured")
    end)


    it("fails if homeStation is not a Station", function()
        local miner = mockValidMiner()

        assert.has_error(function()
            Ship:behaveAsMiner(miner, nil, function() end)
        end, "Expected homeStation to be a Station, but got <nil>")
        assert.has_error(function()
            Ship:behaveAsMiner(miner, 42, function() end)
        end, "Expected homeStation to be a Station, but got <number>42")
        assert.has_error(function()
            Ship:behaveAsMiner(miner, SpaceShip():setCallSign("Test"), function() end)
        end, "Expected homeStation to be a Station, but got <SpaceShip>\"Test\"")
    end)
    it("fails if station does not have storage", function()
        local station = SpaceStation():setCallSign("Home")
        local miner = mockValidMiner()

        assert.has_error(function()
            Ship:behaveAsMiner(miner, station, function() end)
        end, "Station Home needs to have storage configured")
    end)
end)