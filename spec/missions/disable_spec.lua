insulate("Missions:disable()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local player = PlayerSpaceship()

    it("should create a valid Mission with one ship", function()
        local mission = Missions:disable(CpuShip())

        assert.is_true(Mission:isMission(mission))
    end)
    it("should create a valid Mission with a function returning a ship", function()
        local mission = Missions:disable(function() return CpuShip() end)

        assert.is_true(Mission:isMission(mission))
    end)
    it("fails if no valid ship is given", function()
        assert.has_error(function() Missions:disable(nil) end)
        assert.has_error(function() Missions:disable(personMock()) end)
        assert.has_error(function() Missions:disable(42) end)
        assert.has_error(function() Missions:disable(SpaceStation()) end)
    end)

    describe(":getTarget()", function()
        it("returns the target when no function is used", function()
            local ship = CpuShip()
            local mission = Missions:disable(ship)

            assert.is_same(ship, mission:getTarget())
        end)
        it("returns the target when no function is used", function()
            local ship = CpuShip()
            local player = PlayerSpaceship()
            local mission = Missions:disable(function() return ship end)

            assert.is_nil(mission:getTarget())
            mission:setPlayer(player)
            mission:accept()
            mission:start()
            assert.is_same(ship, mission:getTarget())
        end)
    end)

    describe("config.onApproach", function()
        it("is called when the player first enters 10u around the target", function()
            local onApproachCalled = 0
            local onApproachArg1 = nil
            local ship = CpuShip()
            local mission
            mission = Missions:disable(ship, { approachDistance = 10000, onApproach = function(arg1)
                onApproachArg1 = arg1
                onApproachCalled = onApproachCalled + 1
            end})

            player:setPosition(20000, 0)
            ship:setPosition(0, 0)

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, onApproachCalled)

            player:setPosition(10001, 0)
            Cron.tick(1)
            assert.is_same(0, onApproachCalled)

            player:setPosition(9999, 0)
            Cron.tick(1)
            assert.is_same(1, onApproachCalled)
            assert.is_same(mission, onApproachArg1)

            Cron.tick(1)
            assert.is_same(1, onApproachCalled)

            player:setPosition(10001, 0)
            Cron.tick(1)
            player:setPosition(9999, 0)
            Cron.tick(1)
            assert.is_same(1, onApproachCalled)
        end)
    end)

    describe("config.onDestruction", function()
        it("is called when ship is completely destroyed", function()
            local onDestructionCalled = 0
            local onDestructionArg1 = nil
            local ship = CpuShip()
            local player = PlayerSpaceship()
            local mission
            mission = Missions:disable(ship, { onDestruction = function(arg1)
                onDestructionArg1 = arg1
                onDestructionCalled = onDestructionCalled + 1
            end})

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, onDestructionCalled)

            ship:destroy()
            Cron.tick(1)
            assert.is_same(1, onDestructionCalled)
            assert.is_same(mission, onDestructionArg1)

            assert.is_same("failed", mission:getState())
        end)
    end)

    describe("config.onSurrender", function()
        it("disabled impulse engine is necessary for surrender", function()
            local onSurrenderCalled = 0
            local onSurrenderArg1 = nil
            local ship = CpuShip()
            local player = PlayerSpaceship()
            local mission
            mission = Missions:disable(ship, {
                damageThreshold = -0.5,
                distanceToFinish = 1000,
                onSurrender = function(arg1)
                    onSurrenderArg1 = arg1
                    onSurrenderCalled = onSurrenderCalled + 1
                end
            })

            ship:setPosition(0, 0)
            player:setPosition(100, 0)

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            ship:setSystemHealth("impulse", 0)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            ship:setSystemHealth("impulse", -0.49)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            ship:setSystemHealth("impulse", -0.5)
            Cron.tick(1)

            assert.is_same(1, onSurrenderCalled)
            assert.is_same(mission, onSurrenderArg1)
        end)

        it("closeness is necessary for surrender", function()
            local onSurrenderCalled = 0
            local onSurrenderArg1 = nil
            local ship = CpuShip()
            local player = PlayerSpaceship()
            local mission
            mission = Missions:disable(ship, {
                damageThreshold = -0.5,
                distanceToFinish = 1000,
                onSurrender = function(arg1)
                    onSurrenderArg1 = arg1
                    onSurrenderCalled = onSurrenderCalled + 1
                end
            })

            ship:setPosition(0, 0)
            player:setPosition(9999, 0)

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            ship:setSystemHealth("impulse", -1)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            player:setPosition(1001, 0)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            player:setPosition(1000, 0)
            Cron.tick(1)
            assert.is_same(1, onSurrenderCalled)
            assert.is_same(mission, onSurrenderArg1)
        end)

        it("warp drive needs to be destroyed too if a ship has it", function()
            local onSurrenderCalled = 0
            local onSurrenderArg1 = nil
            local ship = CpuShip()
            ship:setWarpDrive(true)
            local player = PlayerSpaceship()
            local mission
            mission = Missions:disable(ship, {
                damageThreshold = -0.5,
                distanceToFinish = 1000,
                onSurrender = function(arg1)
                    onSurrenderArg1 = arg1
                    onSurrenderCalled = onSurrenderCalled + 1
                end
            })

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            ship:setSystemHealth("impulse", -1)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            ship:setSystemHealth("warp", 0)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)


            ship:setSystemHealth("warp", -0.49)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            ship:setSystemHealth("warp", -0.5)
            Cron.tick(1)
            assert.is_same(1, onSurrenderCalled)
            assert.is_same(mission, onSurrenderArg1)
        end)

        it("jump drive needs to be destroyed too if a ship has it", function()
            local onSurrenderCalled = 0
            local onSurrenderArg1 = nil
            local ship = CpuShip()
            ship:setJumpDrive(true)
            local player = PlayerSpaceship()
            local mission
            mission = Missions:disable(ship, {
                damageThreshold = -0.5,
                distanceToFinish = 1000,
                onSurrender = function(arg1)
                    onSurrenderArg1 = arg1
                    onSurrenderCalled = onSurrenderCalled + 1
                end
            })

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            ship:setSystemHealth("impulse", -1)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            ship:setSystemHealth("jumpdrive", 0)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)


            ship:setSystemHealth("jumpdrive", -0.49)
            Cron.tick(1)
            assert.is_same(0, onSurrenderCalled)

            ship:setSystemHealth("jumpdrive", -0.5)
            Cron.tick(1)
            assert.is_same(1, onSurrenderCalled)
            assert.is_same(mission, onSurrenderArg1)
        end)
    end)

    it("can run a successful mission", function()
        local ship = CpuShip()
        local player = PlayerSpaceship()
        local mission
        mission = Missions:disable(ship, {
            damageThreshold = -0.5,
            distanceToFinish = 1000,
        })

        ship:setPosition(0, 0)
        player:setPosition(9999, 0)

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        Cron.tick(1)
        assert.is_same("started", mission:getState())

        player:setPosition(500, 0)
        Cron.tick(1)
        assert.is_same("started", mission:getState())

        ship:setSystemHealth("impulse", -1)
        Cron.tick(1)
        assert.is_same("successful", mission:getState())
    end)
end)