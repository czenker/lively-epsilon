insulate("Player", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe(":withMissionTracker()", function()
        it("creates a valid mission tracker", function()
            local player = PlayerSpaceship()
            Player:withMissionTracker(player)

            assert.is_true(Player:hasMissionTracker(player))
        end)

        it("fails if the first argument is not a player", function()
            assert.has_error(function() Player:withMissionTracker(42) end)
        end)

        it("fails if the first argument is already a mission tracker player", function()
            local player = PlayerSpaceship()
            Player:withMissionTracker(player)

            assert.has_error(function() Player:withMissionTracker(player) end)
        end)
    end)

    describe(":addMission()", function()
        it("adds a mission", function()
            local player = PlayerSpaceship()
            Player:withMissionTracker(player)

            local mission = startedMissionWithBrokerMock()

            player:addMission(mission)

            assert.is_same(1, Util.size(player:getStartedMissions()))
        end)

        it("fails if the first parameter is not a mission", function()
            local player = PlayerSpaceship()
            Player:withMissionTracker(player)

            assert.has_error(function() player:addMission(42) end)
        end)
    end)

    describe(":getStartedMissions()", function()
        it("returns all started missions", function()
            local player = PlayerSpaceship()
            Player:withMissionTracker(player)

            player:addMission(startedMissionWithBrokerMock())
            player:addMission(startedMissionWithBrokerMock())
            player:addMission(startedMissionWithBrokerMock())

            assert.is_same(3, Util.size(player:getStartedMissions()))
        end)

        it("does not return missions that do not have the state started", function()
            local player = PlayerSpaceship()
            Player:withMissionTracker(player)

            player:addMission(missionWithBrokerMock())
            player:addMission(acceptedMissionWithBrokerMock())
            player:addMission(declinedMissionWithBrokerMock())
            player:addMission(failedMissionWithBrokerMock())
            player:addMission(successfulMissionWithBrokerMock())

            assert.is_same(0, Util.size(player:getStartedMissions()))
        end)

        it("manipulating the result set does not add missions", function()
            local player = PlayerSpaceship()
            Player:withMissionTracker(player)

            player:addMission(startedMissionWithBrokerMock())

            local missions = player:getStartedMissions()
            table.insert(missions, startedMissionWithBrokerMock())

            assert.is_same(1, Util.size(player:getStartedMissions()))
        end)
    end)

end)