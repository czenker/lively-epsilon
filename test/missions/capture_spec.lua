insulate("Missions", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local player = eePlayerMock()

    describe("capture()", function()
        it("should create a valid Mission with one ship", function()
            local ship = eeCpuShipMock()
            local mission = Missions:capture(ship)

            assert.is_true(Mission.isMission(mission))
            assert.is_same(ship, mission:getBearer())
            assert.is_nil(mission:getItemObject())
        end)
        it("should create a valid Mission with one station", function()
            local station = eeStationMock()
            local mission = Missions:capture(station)

            assert.is_true(Mission.isMission(mission))
            assert.is_same(station, mission:getBearer())
            assert.is_nil(mission:getItemObject())
        end)
        it("should fail if a person is given instead of a bearer", function()
            assert.has_error(function() Missions:capture(personMock()) end)
        end)
        it("should fail if nil is given instead of a bearer", function()
            assert.has_error(function() Missions:capture(nil) end)
        end)

        it("should create a valid Mission if a callback function is given that returns one ship", function()
            local ship = eeCpuShipMock()
            local mission = Missions:capture(function() return ship end)
            assert.is_true(Mission.isMission(mission))
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            assert.is_same(ship, mission:getBearer())
            assert.is_nil(mission:getItemObject())
        end)
        it("fails if a call back function is given, but returns a person", function()
            local mission = Missions:capture(function() return personMock() end)
            mission:setPlayer(player)
            assert.has_error(function()
                mission:accept()
                mission:start()
            end)
        end)
        it("fails if a call back function is given, but returns a person", function()
            local mission = Missions:capture(function() return nil end)
            mission:setPlayer(player)
            assert.has_error(function()
                mission:accept()
                mission:start()
            end)
        end)

        it("fails if second parameter is a number", function()
            assert.has_error(function() Missions:capture(eeCpuShipMock(), 3) end)
        end)
    end)

    describe("onApproach()", function()
        it("is called when the player first enters around the bearer", function()
            local onApproachCalled = 0
            local bearer = eeStationMock()
            local mission
            mission = Missions:capture(bearer, {
                approachDistance = 10000,
                onApproach = function(callMission, callEnemy)
                    assert.is_same(mission, callMission)
                    assert.is_same(bearer, callEnemy)
                    onApproachCalled = onApproachCalled + 1
                end,
            })

            player:setPosition(20000, 0)
            bearer:setPosition(0, 0)

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(0, onApproachCalled)

            player:setPosition(10001, 0)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(0, onApproachCalled)

            player:setPosition(9999, 0)
            Cron.tick(1)
            assert.is_same(1, onApproachCalled)

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, onApproachCalled)

            player:setPosition(10001, 0)
            Cron.tick(1)
            Cron.tick(1)
            player:setPosition(9999, 0)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, onApproachCalled)
        end)
    end)

    describe("onBearerDestruction()", function()
        it("is called when the bearer is destroyed", function()
            local onBearerDestructionCalled = 0
            local bearer = eeStationMock()
            local mission
            mission = Missions:capture(bearer, {
                onBearerDestruction = function(callMission, lastX, lastY)
                    assert.is_same(mission, callMission)
                    assert.is_same(4200, lastX)
                    assert.is_same(-4200, lastY)
                    onBearerDestructionCalled = onBearerDestructionCalled + 1
                end,
            })

            bearer:setPosition(4200, -4200)

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(0, onBearerDestructionCalled)
            assert.is_same(bearer, mission:getBearer())
            assert.is_nil(mission:getItemObject())

            bearer:destroy()
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, onBearerDestructionCalled)

            assert.is_nil(mission:getBearer())
            assert.is_true(isEeObject(mission:getItemObject()))
        end)
        it("allows to return a custom itemObject", function()
            local bearer = eeStationMock()
            local itemObject = eeCpuShipMock()
            local mission
            mission = Missions:capture(bearer, {
                onBearerDestruction = function(callMission, lastX, lastY)
                    assert.is_same(mission, callMission)
                    assert.is_same(4200, lastX)
                    assert.is_same(-4200, lastY)
                    return itemObject
                end,
            })

            bearer:setPosition(4200, -4200)

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            Cron.tick(1)
            bearer:destroy()

            Cron.tick(1)

            assert.is_nil(mission:getBearer())
            assert.is_same(itemObject, mission:getItemObject())
        end)
    end)

    describe("onItemDestruction()", function()
        it("is called when the item is destroyed and the player is too far", function()
            local onItemDestructionCalled = 0
            local mission
            mission = Missions:capture(eeStationMock(), {
                onItemDestruction = function(callMission, lastX, lastY)
                    assert.is_same(mission, callMission)
                    assert.is_same(4200, lastX)
                    assert.is_same(-4200, lastY)
                    onItemDestructionCalled = onItemDestructionCalled + 1
                end,
            })

            mission:getBearer():setPosition(4200, -4200)
            player:setPosition(0, 0)
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, onItemDestructionCalled)
            mission:getBearer():destroy()

            Cron.tick(1)

            local x, y = mission:getItemObject():getPosition()
            assert.is_same({4200, -4200}, {x,y})

            Cron.tick(1)
            assert.is_same(0, onItemDestructionCalled)

            mission:getItemObject():destroy()
            Cron.tick(1)
            assert.is_same(1, onItemDestructionCalled)
        end)
    end)

    describe("onPickup()", function()
        it("is called when the item is destroyed and the player is close enough", function()
            local onPickupCalled = 0
            local mission
            mission = Missions:capture(eeStationMock(), {
                onPickup = function(callMission)
                    assert.is_same(mission, callMission)
                    onPickupCalled = onPickupCalled + 1
                end,
            })

            mission:getBearer():setPosition(4200, -4200)
            player:setPosition(4100, -4200)
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, onPickupCalled)
            mission:getBearer():destroy()

            Cron.tick(1)

            local x, y = mission:getItemObject():getPosition()
            assert.is_same({4200, -4200}, {x,y})

            Cron.tick(1)
            assert.is_same(0, onPickupCalled)

            mission:getItemObject():destroy()
            Cron.tick(1)
            assert.is_same(1, onPickupCalled)
        end)
    end)

    it("successful mission", function()
        local mission = Missions:capture(eeStationMock())

        mission:getBearer():setPosition(0,0)
        player:setPosition(0,0)
        mission:setPlayer(player)
        mission:accept()
        mission:start()

        Cron.tick(1)
        mission:getBearer():destroy()
        Cron.tick(1)
        mission:getItemObject():destroy()
        Cron.tick(1)

        assert.is_same("successful", mission:getState())
    end)

    it("fails when itemObject is destroyed when the player is too far away", function()
        local mission = Missions:capture(eeStationMock())

        mission:getBearer():setPosition(0,0)
        player:setPosition(4200,4200)
        mission:setPlayer(player)
        mission:accept()
        mission:start()

        Cron.tick(1)
        mission:getBearer():destroy()
        Cron.tick(1)
        mission:getItemObject():destroy()
        Cron.tick(1)

        assert.is_same("failed", mission:getState())
    end)
end)