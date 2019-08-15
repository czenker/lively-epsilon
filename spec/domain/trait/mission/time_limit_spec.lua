insulate("Mission:withTimeLimit()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("should create a valid Mission with time limit", function()
        local mission = Mission:new()
        Mission:withTimeLimit(mission, 10)

        assert.is_true(Mission:isTimeLimitMission(mission))
    end)

    it("fails if mission is invalid", function()
        assert.has_error(function() Mission:withTimeLimit(nil, 10) end)
        assert.has_error(function() Mission:withTimeLimit(PlayerSpaceship(), 10) end)
        assert.has_error(function() Mission:withTimeLimit(123, 10) end)
    end)

    it("fails if the mission already has a time limit", function()
        local mission = Mission:new()
        Mission:withTimeLimit(mission, 10)

        assert.has_error(function() Mission:withTimeLimit(mission, 10) end)
    end)

    it("fails if the mission has been started already", function()
        local mission = Mission:new()
        mission:accept()
        mission:start()

        assert.has_error(function() Mission:withTimeLimit(mission, 10) end)
    end)

    it("fails to start if no time limit is set", function()
        local mission = Mission:new()
        Mission:withTimeLimit(mission)

        mission:accept()

        assert.has_error(function() mission:start() end)

        mission:setTimeLimit(10)
        mission:start()
    end)

    it("makes the mission fail if the time is up", function()
        local mission = Mission:new()
        Mission:withTimeLimit(mission, 10)

        mission:accept()
        mission:start()

        assert.is_same("started", mission:getState())
        for _ = 1,9 do
            Cron.tick(1)
            assert.is_same("started", mission:getState())
        end

        Cron.tick(1.5)
        assert.is_same("failed", mission:getState())
    end)

    describe(":setTimeLimit()", function()
        it("sets the time limit", function()
            local mission = Mission:new()
            Mission:withTimeLimit(mission)

            mission:setTimeLimit(10)

            assert.is_same(10, mission:getRemainingTime())
        end)
        it("fails on non-positive numbers", function()
            local mission = Mission:new()
            Mission:withTimeLimit(mission)

            assert.has_error(function() mission:setTimeLimit(nil) end)
            assert.has_error(function() mission:setTimeLimit(-1) end)
            assert.has_error(function() mission:setTimeLimit(0) end)
            assert.has_error(function() mission:setTimeLimit(PlayerSpaceship()) end)
        end)
    end)

    describe(":modifyTimeLimit()", function()
        it("can increase the time limit", function()
            local mission = Mission:new()
            Mission:withTimeLimit(mission, 10)

            mission:modifyTimeLimit(10)

            assert.is_same(20, mission:getRemainingTime())
        end)
        it("can decrease the time limit", function()
            local mission = Mission:new()
            Mission:withTimeLimit(mission, 10)

            mission:modifyTimeLimit(-5)

            assert.is_same(5, mission:getRemainingTime())
        end)
        it("fails on anything but a number", function()
            local mission = Mission:new()
            Mission:withTimeLimit(mission)

            assert.has_error(function() mission:modifyTimeLimit(nil) end)
            assert.has_error(function() mission:modifyTimeLimit(PlayerSpaceship()) end)
        end)
    end)

    describe(":getRemainingTime()", function()
        it("never gets negative", function()
            local mission = Mission:new()
            Mission:withTimeLimit(mission, 0.5)

            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, mission:getRemainingTime())
        end)
    end)

    it("allows to manipulate the time limit on a running mission", function()
        local mission = Mission:new()
        Mission:withTimeLimit(mission, 10)

        mission:accept()
        mission:start()

        assert.is_same(0, mission:getElapsedTime())
        assert.is_same(10, mission:getRemainingTime())

        Cron.tick(1)
        assert.is_same(1, mission:getElapsedTime())
        assert.is_same(9, mission:getRemainingTime())

        mission:setTimeLimit(42)
        assert.is_same(1, mission:getElapsedTime())
        assert.is_same(41, mission:getRemainingTime())

        Cron.tick(1)
        assert.is_same(2, mission:getElapsedTime())
        assert.is_same(40, mission:getRemainingTime())

        mission:modifyTimeLimit(-5)
        assert.is_same(2, mission:getElapsedTime())
        assert.is_same(35, mission:getRemainingTime())

        Cron.tick(1)
        assert.is_same(3, mission:getElapsedTime())
        assert.is_same(34, mission:getRemainingTime())

        mission:modifyTimeLimit(2)
        assert.is_same(3, mission:getElapsedTime())
        assert.is_same(36, mission:getRemainingTime())
    end)

    it("does not start the timer before mission is started", function()
        local mission = Mission:new()
        Mission:withTimeLimit(mission, 10)

        assert.is_same(0, mission:getElapsedTime())
        assert.is_same(10, mission:getRemainingTime())

        Cron.tick(1)
        assert.is_same(0, mission:getElapsedTime())
        assert.is_same(10, mission:getRemainingTime())

        mission:accept()
        assert.is_same(0, mission:getElapsedTime())
        assert.is_same(10, mission:getRemainingTime())

        Cron.tick(1)
        assert.is_same(0, mission:getElapsedTime())
        assert.is_same(10, mission:getRemainingTime())

        mission:start()
        assert.is_same(0, mission:getElapsedTime())
        assert.is_same(10, mission:getRemainingTime())

        Cron.tick(1)
        assert.is_same(1, mission:getElapsedTime())
        assert.is_same(9, mission:getRemainingTime())
    end)
end)