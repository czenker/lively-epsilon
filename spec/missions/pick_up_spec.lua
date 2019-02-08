insulate("Missions:pickUp()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local player = PlayerSpaceship()

    it("should create a valid Mission with an artifact", function()
        local artifact = Artifact()
        local mission = Missions:pickUp(artifact)

        assert.is_true(Mission:isMission(mission))

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        assert.is_same({artifact}, mission:getPickUps())
        assert.is_same(1, mission:countPickUps())
    end)
    it("should create a valid Mission with a supply drop", function()
        local supplyDrop = SupplyDrop()
        local mission = Missions:pickUp(supplyDrop)

        assert.is_true(Mission:isMission(mission))

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        assert.is_same({supplyDrop}, mission:getPickUps())
        assert.is_same(1, mission:countPickUps())
    end)
    it("should create a valid Mission with a supply drop and artifact", function()
        local artifact = Artifact()
        local supplyDrop = SupplyDrop()
        local mission = Missions:pickUp({artifact, supplyDrop})

        assert.is_true(Mission:isMission(mission))

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        assert.contains_value(artifact, mission:getPickUps())
        assert.contains_value(supplyDrop, mission:getPickUps())
        assert.is_same(2, mission:countPickUps())
    end)
    it("should create a valid Mission with a function returning an artifact", function()
        local artifact = Artifact()
        local mission = Missions:pickUp(function() return artifact end)

        assert.is_true(Mission:isMission(mission))

        assert.is_nil(mission:getPickUps())
        assert.is_nil(mission:countPickUps())

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        assert.is_same({artifact}, mission:getPickUps())
        assert.is_same(1, mission:countPickUps())
    end)
    it("should create a valid Mission with a function returning a supply drop", function()
        local supplyDrop = SupplyDrop()
        local mission = Missions:pickUp(function() return supplyDrop end)

        assert.is_true(Mission:isMission(mission))

        assert.is_nil(mission:getPickUps())
        assert.is_nil(mission:countPickUps())

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        assert.is_same({supplyDrop}, mission:getPickUps())
        assert.is_same(1, mission:countPickUps())
    end)
    it("should create a valid Mission with a function returning a supply drop and artifact", function()
        local artifact = Artifact()
        local supplyDrop = SupplyDrop()
        local mission = Missions:pickUp(function() return {artifact, supplyDrop} end)

        assert.is_true(Mission:isMission(mission))

        assert.is_nil(mission:getPickUps())
        assert.is_nil(mission:countPickUps())

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        assert.contains_value(artifact, mission:getPickUps())
        assert.contains_value(supplyDrop, mission:getPickUps())
        assert.is_same(2, mission:countPickUps())
    end)
    it("fails if first argument is invalid", function()
        assert.has_error(function() Mission:pickUp(SpaceStation()) end)
        assert.has_error(function() Mission:pickUp(nil) end)
        assert.has_error(function() Mission:pickUp(42) end)
        assert.has_error(function() Mission:pickUp({SpaceStation(), SupplyDrop()}) end)

        assert.has_error(function() Mission:pickUp(function()
            return SpaceStation()
        end) end)
        assert.has_error(function() Mission:pickUp(function()
            return nil
        end) end)
        assert.has_error(function() Mission:pickUp(function()
            return 42
        end) end)
        assert.has_error(function() Mission:pickUp(function()
            return {SpaceStation(), SupplyDrop()}
        end) end)
    end)

    it("can run a happy scenario without return to station", function()
        local artifact = Artifact()
        local supplyDrop = SupplyDrop()
        local player = PlayerSpaceship()

        local onStartCalled, onSuccessCalled, onEndCalled = 0, 0, 0
        local onPickUpCalled, onPickUpArg1, onPickUpArg2 = 0, nil, nil
        local onAllPickedUpCalled, onAllPickedUpArg1 = 0, nil
        local mission = Missions:pickUp({artifact, supplyDrop}, {
            onStart = function() onStartCalled = onStartCalled + 1 end,
            onPickUp = function(arg1, arg2)
                onPickUpCalled = onPickUpCalled + 1
                onPickUpArg1 = arg1
                onPickUpArg2 = arg2
            end,
            onAllPickedUp = function(arg1)
                onAllPickedUpCalled = onAllPickedUpCalled + 1
                onAllPickedUpArg1 = arg1
            end,
            onSuccess = function() onSuccessCalled = onSuccessCalled + 1 end,
            onEnd = function() onEndCalled = onEndCalled + 1 end,
        })

        assert.is_true(Mission:isMission(mission))

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        assert.contains_value(artifact, mission:getPickUps())
        assert.contains_value(supplyDrop, mission:getPickUps())
        assert.is_same(2, mission:countPickUps())
        assert.is_nil(mission:getDeliveryStation())
        assert.is_same(1, onStartCalled)
        assert.is_same(0, onPickUpCalled)
        assert.is_same(0, onAllPickedUpCalled)
        assert.is_same(0, onSuccessCalled)
        assert.is_same(0, onEndCalled)

        artifact:pickUp(player)
        assert.is_same(1, onPickUpCalled)
        assert.is_same(mission, onPickUpArg1)
        assert.is_same(artifact, onPickUpArg2)
        assert.is_same(0, onAllPickedUpCalled)

        supplyDrop:pickUp(player)
        assert.is_same(2, onPickUpCalled)
        assert.is_same(mission, onPickUpArg1)
        assert.is_same(supplyDrop, onPickUpArg2)
        assert.is_same(1, onAllPickedUpCalled)
        assert.is_same(mission, onAllPickedUpArg1)
        assert.is_same(1, onSuccessCalled)
        assert.is_same(1, onEndCalled)
    end)

    it("fails if a pickup is picked up by a different player", function()
        local artifact = Artifact()
        local supplyDrop = SupplyDrop()
        local player = PlayerSpaceship()
        local evilPlayer = PlayerSpaceship()

        local onPickUpCalled, onFailureCalled, onEndCalled = 0, 0, 0
        local mission = Missions:pickUp({artifact, supplyDrop}, {
            onPickUp = function() onPickUpCalled = onPickUpCalled + 1 end,
            onFailure = function() onFailureCalled = onFailureCalled + 1 end,
            onEnd = function() onEndCalled = onEndCalled + 1 end,
        })

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        artifact:pickUp(evilPlayer)
        assert.is_same(0, onPickUpCalled)
        assert.is_same(1, onFailureCalled)
        assert.is_same(1, onEndCalled)
    end)
    it("fails if a pickup disappears", function()
        local artifact = Artifact()
        local supplyDrop = SupplyDrop()
        local player = PlayerSpaceship()

        local mission = Missions:pickUp({artifact, supplyDrop})

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        Cron.tick(1)
        artifact:destroy()
        Cron.tick(1)
        assert.is_same("failed", mission:getState())
    end)

    it("can run a happy scenario with return to station", function()
        local artifact = Artifact()
        local supplyDrop = SupplyDrop()
        local station = SpaceStation()
        local player = PlayerSpaceship()

        local onStartCalled, onSuccessCalled, onEndCalled = 0, 0, 0
        local onPickUpCalled, onPickUpArg1, onPickUpArg2 = 0, nil, nil
        local onAllPickedUpCalled, onAllPickedUpArg1 = 0, nil
        local mission = Missions:pickUp({artifact, supplyDrop}, station, {
            onStart = function() onStartCalled = onStartCalled + 1 end,
            onPickUp = function(arg1, arg2)
                onPickUpCalled = onPickUpCalled + 1
                onPickUpArg1 = arg1
                onPickUpArg2 = arg2
            end,
            onAllPickedUp = function(arg1)
                onAllPickedUpCalled = onAllPickedUpCalled + 1
                onAllPickedUpArg1 = arg1
            end,
            onSuccess = function() onSuccessCalled = onSuccessCalled + 1 end,
            onEnd = function() onEndCalled = onEndCalled + 1 end,
        })

        assert.is_true(Mission:isMission(mission))

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        assert.contains_value(artifact, mission:getPickUps())
        assert.contains_value(supplyDrop, mission:getPickUps())
        assert.is_same(2, mission:countPickUps())
        assert.is_same(station, mission:getDeliveryStation())
        assert.is_same(1, onStartCalled)
        assert.is_same(0, onPickUpCalled)
        assert.is_same(0, onAllPickedUpCalled)
        assert.is_same(0, onSuccessCalled)
        assert.is_same(0, onEndCalled)

        artifact:pickUp(player)
        assert.is_same(1, onPickUpCalled)
        assert.is_same(mission, onPickUpArg1)
        assert.is_same(artifact, onPickUpArg2)
        assert.is_same(0, onAllPickedUpCalled)

        supplyDrop:pickUp(player)
        assert.is_same(2, onPickUpCalled)
        assert.is_same(mission, onPickUpArg1)
        assert.is_same(supplyDrop, onPickUpArg2)
        assert.is_same(1, onAllPickedUpCalled)
        assert.is_same(mission, onAllPickedUpArg1)

        Cron.tick(1)

        assert.is_same(0, onSuccessCalled)
        assert.is_same(0, onEndCalled)

        player:setDockedAt(station)
        Cron.tick(1)
        assert.is_same(1, onSuccessCalled)
        assert.is_same(1, onEndCalled)
    end)

    it("fails if deliveryStation disappears", function()
        local artifact = Artifact()
        local supplyDrop = SupplyDrop()
        local station = SpaceStation()
        local player = PlayerSpaceship()

        local mission = Missions:pickUp({artifact, supplyDrop}, station)

        assert.is_true(Mission:isMission(mission))

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        station:destroy()
        Cron.tick(1)
        assert.is_same("failed", mission:getState())
    end)
end)