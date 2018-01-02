insulate("Mission", function()
    require "lively_epsilon"
    require "test.mocks"

    local function missionWithBrokerMock(config)
        local mission = missionMock()
        Mission:withBroker(mission, "Hello World", config)
        return mission
    end

    describe("withBroker()", function()
        it("should create a valid Mission with story", function()
            local mission = missionMock()
            Mission:withBroker(mission, "Hello World")

            assert.is_true(Mission.isBrokerMission(mission))
        end)

        it("fails if no mission is given", function()
            local mission = missionMock()

            assert.has_error(function() Mission:withBroker(nil, "Hello World") end)
        end)

        it("fails if the mission is already a story mission", function()
            local mission = missionMock()
            Mission:withBroker(mission, "Hello World")

            assert.has_error(function() Mission:withBroker(mission, "Hello World") end)
        end)

        it("fails if no title is given", function()
            local mission = missionMock()

            assert.has_error(function() Mission:withBroker(mission) end)
        end)

        it("fails if the config is not a table", function()
            local mission = missionMock()

            assert.has_error(function() Mission:withBroker(mission, "Hello World", "thisBreaks") end)
        end)

        it("fails if the description is a number", function()
            assert.has_error(function() missionWithBrokerMock({description = 42}) end)
        end)
    end)

    describe("getTitle", function()
        it("returns the title if it is a string", function()
            local title = "Hello World"
            local mission = missionMock()
            Mission:withBroker(mission, title)

            assert.is_same(title, mission:getTitle())
        end)

        it("returns the title if it is a function", function()
            local title = "Hello World"
            local mission = missionMock()
            Mission:withBroker(mission, function(callMission)
                assert.is_same(mission, callMission)
                return title
            end)

            assert.is_same(title, mission:getTitle())
        end)
    end)

    describe("getDescription", function()
        it("returns the description if it is a string", function()
            local description = "This is a mission"
            local mission = missionWithBrokerMock({description = description})

            assert.is_same(description, mission:getDescription())
        end)

        it("returns the description if it is a function", function()
            local description = "This is a mission"
            local mission
            mission = missionWithBrokerMock({description = function(callMission)
                assert.is_same(mission, callMission)
                return description
            end})

            assert.is_same(description, mission:getDescription())
        end)
    end)

    describe("getAcceptMessage", function()
        it("returns the message if it is a string", function()
            local message = "Thanks for taking that mission"
            local mission = missionWithBrokerMock({acceptMessage = message })

            assert.is_same(message, mission:getAcceptMessage())
        end)

        it("returns the message if it is a function", function()
            local message = "Thanks for taking that mission"
            local mission
            mission = missionWithBrokerMock({acceptMessage = function(callMission)
                assert.is_same(mission, callMission)
                return message
            end})

            assert.is_same(message, mission:getAcceptMessage())
        end)
    end)

    describe("accept()", function()
        it("can be called if MissionBroker and Player are set", function()
            local mission = missionWithBrokerMock()
            local station = eeStationMock()
            local player = eePlayerMock()

            mission:setMissionBroker(station)
            mission:setPlayer(player)

            mission:accept()
        end)

        it("also calls the original implementation", function()
            local originalCalled = false

            local mission = missionMock()
            mission.accept = function() originalCalled = true end
            Mission:withBroker(mission, "Hello World")
            mission:setMissionBroker(eeStationMock())
            mission:setPlayer(eePlayerMock())

            mission:accept()
            assert.is_true(originalCalled)
        end)

        it("can not be called if no MissionBroker is set", function()
            local mission = missionWithBrokerMock()
            local player = eePlayerMock()

            mission:setPlayer(player)

            assert.has_error(function() mission:accept() end)
        end)

        it("can not be called if Player is not set", function()
            local mission = missionWithBrokerMock()
            local station = eeStationMock()

            mission:setMissionBroker(station)

            assert.has_error(function() mission:accept() end)
        end)

    end)

    describe("getMissionBroker()", function()
        it("returns the set MissionBroker", function()
            local mission = missionWithBrokerMock()
            local station = eeStationMock()

            mission:setMissionBroker(station)

            assert.is_same(station, mission:getMissionBroker())
        end)
    end)
    describe("setPlayer()", function()
        it("fails if argument is not a player", function()
            local mission = missionWithBrokerMock()

            assert.has_error(function()mission:setPlayer(42) end)
        end)
    end)
    describe("getPlayer()", function()
        it("returns the set MissionPlayer", function()
            local mission = missionWithBrokerMock()
            local player = eePlayerMock()

            mission:setPlayer(player)

            assert.is_same(player, mission:getPlayer())
        end)
    end)

end)