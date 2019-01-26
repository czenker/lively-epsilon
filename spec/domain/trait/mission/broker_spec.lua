insulate("Mission", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local function missionWithBrokerMock(config)
        local mission = missionMock()
        Mission:withBroker(mission, "Hello World", config)
        return mission
    end

    describe("withBroker()", function()
        it("should create a valid Mission with story", function()
            local mission = missionMock()
            Mission:withBroker(mission, "Hello World")

            assert.is_true(Mission:isBrokerMission(mission))
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

        it("fails if the mission has been accepted already", function()
            local mission = missionMock()
            mission:accept()

            assert.has_error(function() Mission:withBroker(mission, "Hello World") end)
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
        it("can be called if MissionBroker is set", function()
            local mission = missionWithBrokerMock()
            local station = SpaceStation()

            mission:setMissionBroker(station)

            mission:accept()
        end)

        it("also calls the original implementation", function()
            local originalCalled = false

            local mission = missionMock()
            mission.accept = function() originalCalled = true end
            Mission:withBroker(mission, "Hello World")
            mission:setMissionBroker(SpaceStation())

            mission:accept()
            assert.is_true(originalCalled)
        end)

        it("can not be called if no MissionBroker is set", function()
            local mission = missionWithBrokerMock()

            assert.has_error(function() mission:accept() end)
        end)
    end)

    describe("getMissionBroker()", function()
        it("returns the set MissionBroker", function()
            local mission = missionWithBrokerMock()
            local station = SpaceStation()

            mission:setMissionBroker(station)

            assert.is_same(station, mission:getMissionBroker())
        end)
    end)
    describe("getHint(), setHint()", function()
        it("returns nil by default", function()
            local mission = missionWithBrokerMock()

            assert.is_nil(mission:getHint())
        end)
        it("returns the set hint", function()
            local mission = missionWithBrokerMock()
            mission:setHint("Use force")

            assert.is_same("Use force", mission:getHint())
        end)
        it("returns the set hint by function", function()
            local mission = missionWithBrokerMock()
            mission:setHint(function(theMission)
                assert.is_same(mission, theMission)
                return "Use force"
            end)

            assert.is_same("Use force", mission:getHint())
        end)
        it("returns nil if the function returns invalid type", function()
            local mission = missionWithBrokerMock()
            mission:setHint(function() return 42 end)

            assert.is_nil(mission:getHint())
        end)
        it("allows to remove the hint", function()
            local mission = missionWithBrokerMock()
            mission:setHint(nil)

            assert.is_nil(mission:getHint())
        end)
        it("fails if number is to be set as hint", function()
            local mission = missionWithBrokerMock()
            assert.has_error(function() mission:setHint(42) end)
        end)
    end)

    it("fails automatically if the broker is destroyed", function()
        local onStartCalled = 0
        local station = SpaceStation()
        local mission = Mission:new({
            onStart = function(self)
                onStartCalled = onStartCalled + 1
            end,
        })
        Mission:withBroker(mission, "Hello World")

        mission:setMissionBroker(station)
        mission:accept()
        mission:start()

        assert.is_same(1, onStartCalled)

        Cron.tick(1)
        assert.is_same("started", mission:getState())

        station:destroy()
        Cron.tick(1)
        assert.is_same("failed", mission:getState())
    end)

end)