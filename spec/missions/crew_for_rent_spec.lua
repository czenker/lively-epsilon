insulate("Missions:crewForRent()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("should create a valid Mission with one ship", function()
        local ship = CpuShip()
        local mission = Missions:crewForRent(ship)

        assert.is_true(Mission:isMission(mission))
        assert.is_same(ship, mission:getNeedy())
        assert.is_same(0, mission:getRepairCrewCount())
    end)

    it("fails to be accepted if player ship does not have Menus", function()
        local ship = CpuShip()
        local mission = Missions:crewForRent(ship)
        local player = PlayerSpaceship()

        mission:setPlayer(player)

        assert.has_error(function()
            mission:accept()
        end)
    end)

    describe("sending crew", function()
        it("should only display the button when the player is close enough to the ship", function()
            local label = "Hello World"
            local ship = CpuShip()
            local player = PlayerSpaceship()
            Player:withMenu(player)
            local mission = Missions:crewForRent(ship, {
                distance = 1000,
                sendCrewLabel = label,
            })
            mission:setPlayer(player)
            player:setPosition(0, 0)
            mission:getNeedy():setPosition(10000, 0)

            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_false(player:hasButton("engineering", label))
            assert.is_false(player:hasButton("engineering+", label))

            mission:getNeedy():setPosition(1001, 0)
            Cron.tick(1)
            assert.is_false(player:hasButton("engineering", label))
            assert.is_false(player:hasButton("engineering+", label))

            mission:getNeedy():setPosition(999, 0)
            Cron.tick(1)
            assert.is_true(player:hasButton("engineering", label))
            assert.is_true(player:hasButton("engineering+", label))

            mission:getNeedy():setPosition(1001, 0)
            Cron.tick(1)
            assert.is_false(player:hasButton("engineering", label))
            assert.is_false(player:hasButton("engineering+", label))

        end)
        it("succeeds when crew count is high enough", function()
            local onCrewArrivedCalled = 0
            local sendCrewFailedCalled = 0
            local ship = CpuShip()
            local player = PlayerSpaceship()
            Player:withMenu(player)
            local mission
            mission = Missions:crewForRent(ship, {
                distance = 1000,
                crewCount = 4,
                sendCrewLabel = "Hello World",
                onCrewArrived = function(callMission)
                    onCrewArrivedCalled = onCrewArrivedCalled + 1
                    assert.is_same(mission, callMission)
                end,
                sendCrewFailed = function(callMission)
                    sendCrewFailedCalled = sendCrewFailedCalled + 1
                end,
            })
            mission:setPlayer(player)
            player:setRepairCrewCount(4)
            player:setPosition(0, 0)
            mission:getNeedy():setPosition(500, 0)

            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, onCrewArrivedCalled)
            assert.is_same(0, sendCrewFailedCalled)
            assert.is_same(4, player:getRepairCrewCount())
            assert.is_same(0, mission:getRepairCrewCount())

            player:clickButton("engineering", "Hello World")
            Cron.tick(1)
            assert.is_same(1, onCrewArrivedCalled)
            assert.is_same(0, sendCrewFailedCalled)

            assert.is_same(0, player:getRepairCrewCount())
            assert.is_same(4, mission:getRepairCrewCount())

        end)
        it("fails when crew count is too low", function()
            local onCrewArrivedCalled = 0
            local sendCrewFailedCalled = 0
            local ship = CpuShip()
            local player = PlayerSpaceship()
            Player:withMenu(player)
            local mission
            mission = Missions:crewForRent(ship, {
                distance = 1000,
                crewCount = 5,
                sendCrewLabel = "Hello World",
                onCrewArrived = function(callMission)
                    onCrewArrivedCalled = onCrewArrivedCalled + 1
                end,
                sendCrewFailed = function(callMission)
                    sendCrewFailedCalled = sendCrewFailedCalled + 1
                    assert.is_same(mission, callMission)
                end,
            })
            mission:setPlayer(player)
            player:setRepairCrewCount(4)
            player:setPosition(0, 0)
            mission:getNeedy():setPosition(500, 0)

            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, onCrewArrivedCalled)
            assert.is_same(0, sendCrewFailedCalled)
            assert.is_same(4, player:getRepairCrewCount())
            assert.is_same(0, mission:getRepairCrewCount())

            player:clickButton("engineering", "Hello World")
            Cron.tick(1)
            assert.is_same(0, onCrewArrivedCalled)
            assert.is_same(1, sendCrewFailedCalled)

            assert.is_same(4, player:getRepairCrewCount())
            assert.is_same(0, mission:getRepairCrewCount())
        end)
    end)
    describe("config.onCrewReady", function()
        it("is called when the crew can be picked up again", function()
            local onCrewReadyCalled = 0
            local player = PlayerSpaceship()
            Player:withMenu(player)
            local mission
            mission = Missions:crewForRent(CpuShip(), {
                duration = 3,
                sendCrewLabel = "Hello World",
                onCrewReady = function(callMission)
                    onCrewReadyCalled = onCrewReadyCalled + 1
                    assert.is_same(mission, callMission)
                end,
            })
            mission:setPlayer(player)
            player:setRepairCrewCount(4)
            player:setPosition(0,0)
            mission:getNeedy():setPosition(0,0)
            mission:accept()
            mission:start()

            assert.is_nil(mission:getTimeToReady())

            Cron.tick(1)
            player:clickButton("engineering", "Hello World")
            Cron.tick(1)
            assert.is_same(2, mission:getTimeToReady())
            Cron.tick(1)
            assert.is_same(1, mission:getTimeToReady())
            assert.is_same(0, onCrewReadyCalled)
            Cron.tick(1)
            assert.is_same(1, onCrewReadyCalled)
            Cron.tick(1)
            assert.is_same(1, onCrewReadyCalled)

            assert.is_same(0, mission:getTimeToReady())
        end)
    end)

    describe("returning crew", function()
        it("should only display the button when the player is close enough to the ship", function()
            local label = "Come Back"
            local ship = CpuShip()
            local player = PlayerSpaceship()
            Player:withMenu(player)
            local mission = Missions:crewForRent(ship, {
                distance = 1000,
                crewCount = 4,
                duration = 5,
                sendCrewLabel = "Hello World",
                returnCrewLabel = label,
            })
            mission:setPlayer(player)
            player:setPosition(0, 0)
            mission:getNeedy():setPosition(0, 0)
            player:setRepairCrewCount(5)
            mission:accept()
            mission:start()

            Cron.tick(1)
            player:clickButton("engineering", "Hello World")

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)

            player:setPosition(10000, 0)
            Cron.tick(1)
            assert.is_false(player:hasButton("engineering", label))
            assert.is_false(player:hasButton("engineering+", label))

            player:setPosition(1001, 0)
            Cron.tick(1)
            assert.is_false(player:hasButton("engineering", label))
            assert.is_false(player:hasButton("engineering+", label))

            player:setPosition(999, 0)
            Cron.tick(1)
            assert.is_true(player:hasButton("engineering", label))
            assert.is_true(player:hasButton("engineering+", label))

            player:setPosition(1001, 0)
            Cron.tick(1)
            assert.is_false(player:hasButton("engineering", label))
            assert.is_false(player:hasButton("engineering+", label))
        end)
        it("should return the crew", function()
            local onCrewReturnedCalled = 0
            local ship = CpuShip()
            local player = PlayerSpaceship()
            Player:withMenu(player)
            local mission
            mission = Missions:crewForRent(ship, {
                distance = 1000,
                crewCount = 1,
                duration = 5,
                sendCrewLabel = "Hello World",
                returnCrewLabel = "Come Back",
                onCrewReturned = function(theMission)
                    onCrewReturnedCalled = onCrewReturnedCalled + 1
                    assert.is_same(mission, theMission)
                end,
            })
            mission:setPlayer(player)
            player:setPosition(0, 0)
            mission:getNeedy():setPosition(0, 0)
            player:setRepairCrewCount(1)
            mission:accept()
            mission:start()

            Cron.tick(1)
            player:clickButton("engineering", "Hello World")

            Cron.tick(5)
            Cron.tick(1)
            assert.is_same(0, onCrewReturnedCalled)
            player:clickButton("engineering", "Come Back")
            assert.is_same(1, onCrewReturnedCalled)
        end)
    end)

    it("successful mission", function()
        local player = PlayerSpaceship()
        Player:withMenu(player)
        local mission
        mission = Missions:crewForRent(CpuShip(), {
            distance = 1000,
            crewCount = 4,
            duration = 5,
            sendCrewLabel = "Hello World",
            returnCrewLabel = "Come Back",
        })
        mission:setPlayer(player)
        player:setPosition(0, 0)
        mission:getNeedy():setPosition(0, 0)
        player:setRepairCrewCount(5)
        mission:accept()
        mission:start()

        Cron.tick(1)
        assert.is_same(5, player:getRepairCrewCount())
        player:clickButton("engineering", "Hello World")
        assert.is_same(1, player:getRepairCrewCount())

        Cron.tick(5)
        Cron.tick(1)
        assert.is_same(1, player:getRepairCrewCount())
        player:clickButton("engineering", "Come Back")
        Cron.tick(1)
        assert.is_same(5, player:getRepairCrewCount())

        assert.is_false(player:hasButton("engineering", "Come Back"))
        assert.is_false(player:hasButton("engineering+", "Come Back"))
        assert.is_same("successful", mission:getState())
    end)

end)