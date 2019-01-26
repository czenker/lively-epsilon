insulate("Mission", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local function missionWithPlayerMock(player)
        local mission = missionMock()
        Mission:forPlayer(mission, player)
        return mission
    end

    local player = PlayerSpaceship()

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

        it("fails if the mission has been accepted already", function()
            local mission = missionMock()
            mission:accept()

            assert.has_error(function() Mission:forPlayer(mission, player) end)
        end)
    end)

    describe("accept()", function()
        it("can be called if Player are set", function()
            local mission = missionWithPlayerMock()
            local player = PlayerSpaceship()

            mission:setPlayer(player)

            mission:accept()
        end)

        it("also calls the original implementation", function()
            local originalCalled = false

            local mission = missionMock()
            mission.accept = function() originalCalled = true end
            Mission:forPlayer(mission, player)
            mission:setPlayer(PlayerSpaceship())

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
            local player = PlayerSpaceship()

            mission:setPlayer(player)

            assert.is_same(player, mission:getPlayer())
        end)
    end)

    it("fails if the player is destroyed", function()
        local player = PlayerSpaceship()

        local onStartCalled = 0
        local mission = Mission:new({
            onStart = function(self)
                onStartCalled = onStartCalled + 1
            end,
        })
        Mission:forPlayer(mission, player)

        mission:setPlayer(player)
        mission:accept()
        mission:start()
        assert.is_same(1, onStartCalled)

        Cron.tick(1)
        assert.is_same("started", mission:getState())

        player:destroy()
        Cron.tick(1)
        assert.is_same("failed", mission:getState())
    end)
end)