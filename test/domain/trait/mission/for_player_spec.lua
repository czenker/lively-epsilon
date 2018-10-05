insulate("Mission", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local function missionWithPlayerMock(player)
        local mission = missionMock()
        Mission:forPlayer(mission, player)
        return mission
    end

    local player = eePlayerMock()

    describe("forPlayer()", function()
        it("should create a valid Mission with player", function()
            local mission = missionMock()
            Mission:forPlayer(mission, player)

            assert.is_true(Mission:isPlayerMission(mission))
        end)

        it("fails if no mission is given", function()
            local mission = missionMock()

            assert.has_error(function() Mission:forPlayer(nil, player) end)
        end)

        it("fails if the mission is already a player mission", function()
            local mission = missionMock()
            Mission:forPlayer(mission, player)

            assert.has_error(function() Mission:forPlayer(mission, player) end)
        end)
    end)

    describe("accept()", function()
        it("can be called if Player are set", function()
            local mission = missionWithPlayerMock()
            local player = eePlayerMock()

            mission:setPlayer(player)

            mission:accept()
        end)

        it("also calls the original implementation", function()
            local originalCalled = false

            local mission = missionMock()
            mission.accept = function() originalCalled = true end
            Mission:forPlayer(mission, player)
            mission:setPlayer(eePlayerMock())

            mission:accept()
            assert.is_true(originalCalled)
        end)

        it("can not be called if Player is not set", function()
            local mission = missionWithPlayerMock()

            assert.has_error(function() mission:accept() end)
        end)

    end)

    describe("setPlayer()", function()
        it("fails if argument is not a player", function()
            local mission = missionWithPlayerMock()

            assert.has_error(function()mission:setPlayer(42) end)
        end)
    end)
    describe("getPlayer()", function()
        it("returns the set Player", function()
            local mission = missionWithPlayerMock()
            local player = eePlayerMock()

            mission:setPlayer(player)

            assert.is_same(player, mission:getPlayer())
        end)
    end)
end)