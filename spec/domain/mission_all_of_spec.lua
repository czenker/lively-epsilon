insulate("Mission:allOf()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe(":allOf()", function()
        it("creates a valid mission and sets the parent mission", function()
            local subMission1 = Mission:new()
            local subMission2 = Mission:new()

            local mission = Mission:allOf(subMission1, subMission2)

            assert.is_true(Mission:isMission(mission))
            assert.is_true(Mission:isSubMission(subMission1))
            assert.is_same(mission, subMission1:getParentMission())
            assert.is_true(Mission:isSubMission(subMission2))
            assert.is_same(mission, subMission2:getParentMission())
        end)
        it("allows to set config", function()
            local subMission1 = Mission:new()
            local subMission2 = Mission:new()

            local onAcceptCalled = false
            local mission = Mission:allOf(subMission1, subMission2, {onAccept = function()
                onAcceptCalled = true
            end})

            mission:accept()
            assert.is_true(onAcceptCalled)
        end)

        it("fails if no sub missions are given", function()
            assert.has_error(function()
                Mission:allOf()
            end)
        end)

        it("fails if no sub missions are given", function()
            assert.has_error(function()
                Mission:allOf()
            end)
        end)

        it("fails on invalid parameters", function()
            assert.has_error(function() Mission:allOf(42) end)
            assert.has_error(function() Mission:allOf({}) end)
            assert.has_error(function() Mission:allOf("broken") end)
            assert.has_error(function() Mission:allOf(CpuShip()) end)
        end)

        it("fails if any sub mission is not \"new\"", function()
            local subMission1 = Mission:new()
            local subMission2 = Mission:new()
            local subMission3 = Mission:new()

            subMission3:accept()
            assert.has_error(function() Mission:allOf(subMission1, subMission2, subMission3) end)

            subMission3:start()
            assert.has_error(function() Mission:allOf(subMission1, subMission2, subMission3) end)

            subMission3:success()
            assert.has_error(function() Mission:allOf(subMission1, subMission2, subMission3) end)
        end)

        it("fails if any sub mission is already part of another mission container", function()
            local subMission1 = Mission:new()
            local subMission2 = Mission:new()
            local subMission3 = Mission:new()
            local subMission4 = Mission:new()

            Mission:allOf(subMission1, subMission4)

            assert.has_error(function() Mission:allOf(subMission1, subMission2, subMission3) end)
        end)
    end)

    it("starts all the missions and finishes if all are completed (happy case)", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()
        local subMission3 = Mission:new()

        local mission = Mission:allOf(subMission1, subMission2, subMission3)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())
        assert.is_same("new", subMission3:getState())

        mission:accept()
        assert.is_same("accepted", mission:getState())
        assert.is_same("accepted", subMission1:getState())
        assert.is_same("accepted", subMission2:getState())
        assert.is_same("accepted", subMission3:getState())

        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("started", subMission2:getState())
        assert.is_same("started", subMission3:getState())

        subMission1:success()
        assert.is_same("started", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("started", subMission2:getState())
        assert.is_same("started", subMission3:getState())

        subMission3:success()
        assert.is_same("started", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("started", subMission2:getState())
        assert.is_same("successful", subMission3:getState())

        subMission2:success()
        assert.is_same("successful", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("successful", subMission2:getState())
        assert.is_same("successful", subMission3:getState())
    end)

    it("fails if any sub mission fails", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()
        local subMission3 = Mission:new()

        local mission = Mission:allOf(subMission1, subMission2, subMission3)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())
        assert.is_same("new", subMission3:getState())

        mission:accept()
        assert.is_same("accepted", mission:getState())
        assert.is_same("accepted", subMission1:getState())
        assert.is_same("accepted", subMission2:getState())
        assert.is_same("accepted", subMission3:getState())

        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("started", subMission2:getState())
        assert.is_same("started", subMission3:getState())

        subMission1:success()
        assert.is_same("started", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("started", subMission2:getState())
        assert.is_same("started", subMission3:getState())

        subMission2:fail()
        assert.is_same("failed", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("failed", subMission2:getState())
        assert.is_same("failed", subMission3:getState())
    end)

    it("makes all sub missions successful if the wrapper mission is set to success", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()
        local subMission3 = Mission:new()

        local mission = Mission:allOf(subMission1, subMission2, subMission3)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())
        assert.is_same("new", subMission3:getState())

        mission:accept()
        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("started", subMission2:getState())
        assert.is_same("started", subMission3:getState())

        subMission2:success()
        assert.is_same("successful", subMission2:getState())

        mission:success()
        assert.is_same("successful", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("successful", subMission2:getState())
        assert.is_same("successful", subMission3:getState())
    end)

    it("makes all sub missions fail if the wrapper mission is set to fail", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()
        local subMission3 = Mission:new()

        local mission = Mission:allOf(subMission1, subMission2, subMission3)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())
        assert.is_same("new", subMission3:getState())

        mission:accept()
        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("started", subMission2:getState())
        assert.is_same("started", subMission3:getState())

        subMission2:success()
        assert.is_same("successful", subMission2:getState())

        mission:fail()
        assert.is_same("failed", mission:getState())
        assert.is_same("failed", subMission1:getState())
        assert.is_same("successful", subMission2:getState())
        assert.is_same("failed", subMission3:getState())
    end)

    it("makes every sub mission a PlayerMission if it is a PlayerMission itself", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()
        Mission:forPlayer(subMission2)
        local subMission3 = Mission:new()
        local player = PlayerSpaceship()

        local mission = Mission:allOf(subMission1, subMission2, subMission3)
        Mission:forPlayer(mission)
        mission:setPlayer(player)

        mission:accept()
        mission:start()

        assert.is_true(Mission:isPlayerMission(subMission1))
        assert.is_same(player, subMission1:getPlayer())
        -- subMission2 was already a player mission, but the player should be set anyways
        assert.is_true(Mission:isPlayerMission(subMission2))
        assert.is_same(player, subMission2:getPlayer())
        assert.is_true(Mission:isPlayerMission(subMission3))
        assert.is_same(player, subMission3:getPlayer())
    end)
end)