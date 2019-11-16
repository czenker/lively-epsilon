insulate("Mission:newChain()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe(":newChain()", function()
        it("creates a valid mission", function()
            local subMission1 = Mission:new()
            local subMission2 = Mission:new()

            local mission = Mission:newChain(subMission1, subMission2)

            assert.is_true(Mission:isMission(mission))
        end)
        it("allows to set config", function()
            local subMission1 = Mission:new()
            local subMission2 = Mission:new()

            local onAcceptCalled = false
            local mission = Mission:newChain(subMission1, subMission2, {onAccept = function()
                onAcceptCalled = true
            end})

            mission:accept()
            assert.is_true(onAcceptCalled)
        end)

        it("fails if no sub missions are given", function()
            assert.has_error(function()
                Mission:newChain()
            end)
        end)

        it("fails if no sub missions are given", function()
            assert.has_error(function()
                Mission:newChain()
            end)
        end)

        it("fails on invalid parameters", function()
            assert.has_error(function() Mission:newChain(42) end)
            assert.has_error(function() Mission:newChain({}) end)
            assert.has_error(function() Mission:newChain("broken") end)
            assert.has_error(function() Mission:newChain(CpuShip()) end)
        end)

        it("fails if any sub mission is not \"new\"", function()
            local subMission1 = Mission:new()
            local subMission2 = Mission:new()
            local subMission3 = Mission:new()

            subMission3:accept()
            assert.has_error(function() Mission:newChain(subMission1, subMission2, subMission3) end)

            subMission3:start()
            assert.has_error(function() Mission:newChain(subMission1, subMission2, subMission3) end)

            subMission3:success()
            assert.has_error(function() Mission:newChain(subMission1, subMission2, subMission3) end)
        end)
    end)

    it("starts the missions one after another (happy case)", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()
        local subMission3 = Mission:new()

        local mission = Mission:newChain(subMission1, subMission2, subMission3)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())
        assert.is_same("new", subMission3:getState())

        mission:accept()
        assert.is_same("accepted", mission:getState())
        assert.is_same("accepted", subMission1:getState())
        assert.is_same("new", subMission2:getState())
        assert.is_same("new", subMission3:getState())

        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("new", subMission2:getState())
        assert.is_same("new", subMission3:getState())

        subMission1:success()
        assert.is_same("started", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("started", subMission2:getState())
        assert.is_same("new", subMission3:getState())

        subMission2:success()
        assert.is_same("started", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("successful", subMission2:getState())
        assert.is_same("started", subMission3:getState())

        subMission3:success()
        assert.is_same("successful", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("successful", subMission2:getState())
        assert.is_same("successful", subMission3:getState())
    end)

    it("fails if the first sub mission fails", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()

        local mission = Mission:newChain(subMission1, subMission2)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:accept()
        assert.is_same("accepted", mission:getState())
        assert.is_same("accepted", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        subMission1:fail()
        assert.is_same("failed", mission:getState())
        assert.is_same("failed", subMission1:getState())
        -- subMission2 state is undefined
    end)

    it("fails if the second sub mission fails", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()

        local mission = Mission:newChain(subMission1, subMission2)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:accept()
        assert.is_same("accepted", mission:getState())
        assert.is_same("accepted", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        subMission1:success()
        assert.is_same("started", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("started", subMission2:getState())

        subMission2:fail()
        assert.is_same("failed", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("failed", subMission2:getState())
    end)

    it("makes the current sub mission successful if the wrapper mission is set to success", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()

        local mission = Mission:newChain(subMission1, subMission2)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:accept()
        assert.is_same("accepted", mission:getState())
        assert.is_same("accepted", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:success()
        assert.is_same("successful", mission:getState())
        assert.is_same("successful", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        -- behavior on any further sub mission state changes are undefined
    end)

    it("makes the current sub mission fail if the wrapper mission is set to failure", function()
        local subMission1 = Mission:new()
        local subMission2 = Mission:new()

        local mission = Mission:newChain(subMission1, subMission2)

        assert.is_same("new", mission:getState())
        assert.is_same("new", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:accept()
        assert.is_same("accepted", mission:getState())
        assert.is_same("accepted", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:start()
        assert.is_same("started", mission:getState())
        assert.is_same("started", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        mission:fail()
        assert.is_same("failed", mission:getState())
        assert.is_same("failed", subMission1:getState())
        assert.is_same("new", subMission2:getState())

        -- behavior on any further sub mission state changes are undefined
    end)
end)