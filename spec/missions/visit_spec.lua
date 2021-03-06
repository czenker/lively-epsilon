insulate("Missions:visit()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("should create a valid Mission", function()
        local station = SpaceStation()
        local mission = Missions:visit(station, to)

        assert.is_true(Mission:isMission(mission))
    end)
    it("fails if first parameter is not a station", function()
        local station = CpuShip()
        assert.has_error(function() Missions:visit(station) end)
    end)
    it("fails if second parameter is a number", function()
        local station = SpaceStation()
        assert.has_error(function() Missions:visit(station, 3) end)
    end)

    it("fails to start if mission is not a broker mission", function()
        local station = SpaceStation()
        local mission = Missions:visit(station)

        assert.has_error(function() mission:accept() end)
    end)

    it("can run a successful mission", function()
        local onVisitCalled = false

        local station = SpaceStation()
        local player = PlayerSpaceship()
        local mission = Missions:visit(station, {
            onVisit = function() onVisitCalled = true end,
        })
        Mission:withBroker(mission, "Dummy")

        mission:setPlayer(player)
        mission:setMissionBroker(station)
        mission:accept()
        mission:start()

        player.isDocked = function()
            return false
        end

        Cron.tick(1)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_false(onVisitCalled)

        player.isDocked = function(self, thing)
            return thing == station
        end

        Cron.tick(1)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_true(onVisitCalled)

        assert.is_same("successful", mission:getState())

    end)
end)