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
        assert.has_error(function() Missions:wayPoints({ 42, "foobar"}) end)
        assert.has_error(function() Missions:wayPoints({ { 42, 42}, { 0, 0}, { "this", "is", "invalid"}}) end)
    end)

    describe(":addWayPoint()", function()
        it("allows to add coordinates", function()
            local mission = Missions:wayPoints()
            mission:addWayPoint(2000, -2000)
        end)
        it("allows to add an EE object", function()
            local mission = Missions:wayPoints()
            mission:addWayPoint(Artifact():setPosition(2000, -2000))
        end)
        it("fails if first parameter is not a number", function()
            local mission = Missions:wayPoints()

            assert.has_error(function() mission:addWayPoint(nil, 0) end)
            assert.has_error(function() mission:addWayPoint("foobar", 0) end)
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

        local artifact = Artifact():setPosition(10000, 0)

        local player = PlayerSpaceship()
        local mission
        mission = Missions:wayPoints({
            {10000, 10000},
            artifact,
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

        -- move artifact to verify the current position of the object is used
        artifact:setPosition(20000, 0)

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
        assert.is_same(artifact, callbackArg2)
        assert.is_same(nil, callbackArg3)
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
                if isEeObject(x) then
                    x, y = x:getPosition()
                end
                if x < 49999 then
                    x = x + 10000
                    if x > 25000 then
                        -- make sure the current position is used and not the one when it was added
                        local artifact = Artifact():setPosition(x / 2, y / 2)
                        self:addWayPoint(artifact)
                        artifact:setPosition(x, y)
                    else
                        self:addWayPoint(x, y)
                    end
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