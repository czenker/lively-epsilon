insulate("Missions:wayPoints()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("should create a valid Mission", function()
        local mission = Missions:wayPoints({ { 0, 0}})

        assert.is_true(Mission:isMission(mission))
    end)
    it("fails if first parameter is a number", function()
        assert.has_error(function() Missions:wayPoints(42) end)
    end)
    it("fails if first parameter does not contain valid data", function()
        -- empty waypoint list
        assert.has_error(function() Missions:wayPoints({ 42, "foobar"}) end)
        assert.has_error(function() Missions:wayPoints({ { 42, 42}, { 0, 0}, { "this", "is", "invalid"}}) end)
    end)

    describe(":addWayPoint()", function()
        it("fails if first parameter is not a number", function()
            local mission = Missions:wayPoints()

            assert.has_error(function() mission:addWayPoint(nil, 0) end)
            assert.has_error(function() mission:addWayPoint("foobar", 0) end)
            assert.has_error(function() mission:addWayPoint(SpaceShip(), 0) end)
        end)
        it("fails if second parameter is not a number", function()
            local mission = Missions:wayPoints()

            assert.has_error(function() mission:addWayPoint(0) end)
            assert.has_error(function() mission:addWayPoint(0, nil) end)
            assert.has_error(function() mission:addWayPoint(0, "foobar") end)
            assert.has_error(function() mission:addWayPoint(0, SpaceShip()) end)
        end)
    end)

    it("can run a successful mission with a static list of waypoints", function()
        local onWayPointCalled = 0
        local callbackArg2 = nil
        local callbackArg3 = nil

        local player = PlayerSpaceship()
        local mission
        mission = Missions:wayPoints({
            {10000, 10000},
            {20000, 0},
            {0, 0}
        }, {
            minDistance = 1000,
            onWayPoint = function(callMission, arg2, arg3)
                onWayPointCalled = onWayPointCalled + 1
                callbackArg2, callbackArg3 = arg2, arg3
                assert.is_same(mission, callMission)
            end,
        })

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        player:setPosition(0, 0)
        Cron.tick(1)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_same(0, mission:countVisitedWayPoints())
        assert.is_same(0, onWayPointCalled)
        assert.is_same("started", mission:getState())

        player:setPosition(20000, 0)
        Cron.tick(1)
        Cron.tick(1)
        Cron.tick(1)
        -- it should not count, because the waypoints should be visited sequentially
        assert.is_same(0, mission:countVisitedWayPoints())
        assert.is_same(0, onWayPointCalled)
        assert.is_same("started", mission:getState())

        player:setPosition(10000, 10000)
        Cron.tick(1)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_same(1, mission:countVisitedWayPoints())
        assert.is_same(1, onWayPointCalled)
        assert.is_same(10000, callbackArg2)
        assert.is_same(10000, callbackArg3)
        assert.is_same("started", mission:getState())

        player:setPosition(20000, 900)
        Cron.tick(1)
        Cron.tick(1)
        Cron.tick(1)
        -- it should allow to be minDistance away
        assert.is_same(2, mission:countVisitedWayPoints())
        assert.is_same(2, onWayPointCalled)
        assert.is_same(20000, callbackArg2)
        assert.is_same(0, callbackArg3)
        assert.is_same("started", mission:getState())

        player:setPosition(200, -300)
        Cron.tick(1)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_same(3, mission:countVisitedWayPoints())
        assert.is_same(3, onWayPointCalled)
        assert.is_same(0, callbackArg2)
        assert.is_same(0, callbackArg3)
        assert.is_same("successful", mission:getState())
    end)

    it("can run a successful mission while adding waypoints dynamically", function()
        local onWayPointCalled = 0

        local player = PlayerSpaceship()
        local mission
        mission = Missions:wayPoints(nil, {
            minDistance = 1000,
            onStart = function(self)
                self:addWayPoint(10000, 0)
            end,
            onWayPoint = function(self, x, y)
                onWayPointCalled = onWayPointCalled + 1
                if x < 49999 then
                    self:addWayPoint(x + 10000, y)
                end
            end,
        })

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        player:setPosition(0, 0)
        Cron.tick(1)
        assert.is_same("started", mission:getState())
        assert.is_same(0, mission:countVisitedWayPoints())
        assert.is_same(0, onWayPointCalled)

        player:setPosition(10000, 0)
        Cron.tick(1)
        assert.is_same("started", mission:getState())
        assert.is_same(1, mission:countVisitedWayPoints())
        assert.is_same(1, onWayPointCalled)

        player:setPosition(20000, 0)
        Cron.tick(1)
        assert.is_same("started", mission:getState())
        assert.is_same(2, mission:countVisitedWayPoints())
        assert.is_same(2, onWayPointCalled)

        player:setPosition(30000, 0)
        Cron.tick(1)
        assert.is_same("started", mission:getState())
        assert.is_same(3, mission:countVisitedWayPoints())
        assert.is_same(3, onWayPointCalled)

        player:setPosition(40000, 0)
        Cron.tick(1)
        assert.is_same("started", mission:getState())
        assert.is_same(4, mission:countVisitedWayPoints())
        assert.is_same(4, onWayPointCalled)

        player:setPosition(50000, 0)
        Cron.tick(1)
        assert.is_same("successful", mission:getState())
        assert.is_same(5, mission:countVisitedWayPoints())
        assert.is_same(5, onWayPointCalled)
    end)
end)