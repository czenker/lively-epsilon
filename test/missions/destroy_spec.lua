insulate("Missions", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local player = PlayerSpaceship()

    describe("destroy()", function()
        it("should create a valid Mission with one ship", function()
            local mission = Missions:destroy(CpuShip())

            assert.is_true(Mission:isMission(mission))
        end)
        it("should create a valid Mission with one station", function()
            local mission = Missions:destroy(SpaceStation())

            assert.is_true(Mission:isMission(mission))
        end)
        it("should create a valid Mission with one WarpJammer", function()
            local mission = Missions:destroy(WarpJammer())

            assert.is_true(Mission:isMission(mission))
        end)
        it("should create a valid Mission with one ScanProbe", function()
            local mission = Missions:destroy(ScanProbe())

            assert.is_true(Mission:isMission(mission))
        end)
        it("should create a valid Mission with mixed space objects", function()
            local mission = Missions:destroy({CpuShip(), SpaceStation(), CpuShip(), WarpJammer(), ScanProbe()})

            assert.is_true(Mission:isMission(mission))
        end)
        it("fails if the first parameter is a person", function()
            assert.has_error(function() Missions:destroy(personMock()) end)
        end)
        it("fails if the first parameter is a table where one item is a person", function()
            assert.has_error(function() Missions:destroy({CpuShip(), SpaceStation(), personMock()}) end)
        end)
        it("fails if the first parameter is not given", function()
            assert.has_error(function() Missions:destroy() end)
        end)

        it("should create a valid Mission if a callback function is given that returns one ship", function()
            local ship = CpuShip()
            local mission = Missions:destroy(function() return ship end)
            assert.is_true(Mission:isMission(mission))
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            assert.is_same({ship}, mission:getValidEnemies())
        end)
        it("should create a valid Mission if a callback function is given that returns one station", function()
            local station = SpaceStation()
            local mission = Missions:destroy(function() return station end)
            assert.is_true(Mission:isMission(mission))
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            assert.is_same({station}, mission:getValidEnemies())
        end)
        it("should create a valid Mission if a callback function is given that returns one warp jammer", function()
            local jammer = WarpJammer()
            local mission = Missions:destroy(function() return jammer end)
            assert.is_true(Mission:isMission(mission))
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            assert.is_same({ jammer }, mission:getValidEnemies())
        end)
        it("should create a valid Mission if a callback function is given that returns one scan probe", function()
            local probe = ScanProbe()
            local mission = Missions:destroy(function() return probe end)
            assert.is_true(Mission:isMission(mission))
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            assert.is_same({ probe }, mission:getValidEnemies())
        end)
        it("should create a valid Mission if a callback function is given that returns mixed space objects", function()
            local thing1 = CpuShip()
            local thing2 = SpaceStation()
            local thing3 = WarpJammer()
            local thing4 = ScanProbe()
            local mission = Missions:destroy(function() return {thing1, thing2, thing3, thing4} end)
            assert.is_true(Mission:isMission(mission))
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            assert.contains_value(thing1, mission:getValidEnemies())
            assert.contains_value(thing2, mission:getValidEnemies())
            assert.contains_value(thing3, mission:getValidEnemies())
            assert.contains_value(thing4, mission:getValidEnemies())
        end)
        it("fails if a call back function is given, but returns a person", function()
            local mission = Missions:destroy(function() return personMock() end)
            mission:setPlayer(player)
            mission:accept()
            assert.has_error(function()
                mission:start()
            end)
        end)
        it("fails if a call back function is given, but returns a table where one item is a person", function()
            local mission = Missions:destroy(function() return {CpuShip(), SpaceStation(), personMock()} end)
            mission:setPlayer(player)
            mission:accept()

            assert.has_error(function()
                mission:start()
            end)
        end)
        it("fails if a call back function is given that returns nil", function()
            local mission = Missions:destroy(function() return nil end)
            mission:setPlayer(player)
            mission:accept()

            assert.has_error(function()
                mission:start()
            end)
        end)

        it("fails if second parameter is a number", function()
            assert.has_error(function() Missions:destroy(CpuShip(), 3) end)
        end)
    end)

    describe("getValidEnemies(), countValidEnemies(), getInvalidEnemies(), countInvalidEnemies(), getEnemies(), countEnemies()", function()
        it("return correct values", function()
            local enemy1 = SpaceStation()
            local enemy2 = CpuShip()
            local enemy3 = CpuShip()
            local enemy4 = WarpJammer()
            local enemy5 = ScanProbe()
            local mission = Missions:destroy({enemy1, enemy2, enemy3, enemy4, enemy5})

            assert.is_same(5, mission:countEnemies())
            assert.is_same(5, mission:countValidEnemies())
            assert.is_same(0, mission:countInvalidEnemies())
            assert.contains_value(enemy1, mission:getEnemies())
            assert.contains_value(enemy2, mission:getEnemies())
            assert.contains_value(enemy3, mission:getEnemies())
            assert.contains_value(enemy4, mission:getEnemies())
            assert.contains_value(enemy5, mission:getEnemies())
            assert.contains_value(enemy1, mission:getValidEnemies())
            assert.contains_value(enemy2, mission:getValidEnemies())
            assert.contains_value(enemy3, mission:getValidEnemies())
            assert.contains_value(enemy4, mission:getValidEnemies())
            assert.contains_value(enemy5, mission:getValidEnemies())
            assert.not_contains_value(enemy1, mission:getInvalidEnemies())
            assert.not_contains_value(enemy2, mission:getInvalidEnemies())
            assert.not_contains_value(enemy3, mission:getInvalidEnemies())
            assert.not_contains_value(enemy4, mission:getInvalidEnemies())
            assert.not_contains_value(enemy5, mission:getInvalidEnemies())

            enemy1:destroy()

            assert.is_same(5, mission:countEnemies())
            assert.is_same(4, mission:countValidEnemies())
            assert.is_same(1, mission:countInvalidEnemies())
            assert.contains_value(enemy1, mission:getEnemies())
            assert.contains_value(enemy2, mission:getEnemies())
            assert.contains_value(enemy3, mission:getEnemies())
            assert.contains_value(enemy4, mission:getEnemies())
            assert.contains_value(enemy5, mission:getEnemies())
            assert.not_contains_value(enemy1, mission:getValidEnemies())
            assert.contains_value(enemy2, mission:getValidEnemies())
            assert.contains_value(enemy3, mission:getValidEnemies())
            assert.contains_value(enemy4, mission:getValidEnemies())
            assert.contains_value(enemy5, mission:getValidEnemies())
            assert.contains_value(enemy1, mission:getInvalidEnemies())
            assert.not_contains_value(enemy2, mission:getInvalidEnemies())
            assert.not_contains_value(enemy3, mission:getInvalidEnemies())
            assert.not_contains_value(enemy4, mission:getInvalidEnemies())
            assert.not_contains_value(enemy5, mission:getInvalidEnemies())

            enemy2:destroy()
            enemy3:destroy()

            assert.is_same(5, mission:countEnemies())
            assert.is_same(2, mission:countValidEnemies())
            assert.is_same(3, mission:countInvalidEnemies())
            assert.contains_value(enemy1, mission:getEnemies())
            assert.contains_value(enemy2, mission:getEnemies())
            assert.contains_value(enemy3, mission:getEnemies())
            assert.contains_value(enemy4, mission:getEnemies())
            assert.contains_value(enemy5, mission:getEnemies())
            assert.not_contains_value(enemy1, mission:getValidEnemies())
            assert.not_contains_value(enemy2, mission:getValidEnemies())
            assert.not_contains_value(enemy3, mission:getValidEnemies())
            assert.contains_value(enemy4, mission:getValidEnemies())
            assert.contains_value(enemy5, mission:getValidEnemies())
            assert.contains_value(enemy1, mission:getInvalidEnemies())
            assert.contains_value(enemy2, mission:getInvalidEnemies())
            assert.contains_value(enemy3, mission:getInvalidEnemies())
            assert.not_contains_value(enemy4, mission:getInvalidEnemies())
            assert.not_contains_value(enemy5, mission:getInvalidEnemies())

            enemy4:destroy()
            enemy5:destroy()

            assert.is_same(5, mission:countEnemies())
            assert.is_same(0, mission:countValidEnemies())
            assert.is_same(5, mission:countInvalidEnemies())
            assert.contains_value(enemy1, mission:getEnemies())
            assert.contains_value(enemy2, mission:getEnemies())
            assert.contains_value(enemy3, mission:getEnemies())
            assert.contains_value(enemy4, mission:getEnemies())
            assert.contains_value(enemy5, mission:getEnemies())
            assert.not_contains_value(enemy1, mission:getValidEnemies())
            assert.not_contains_value(enemy2, mission:getValidEnemies())
            assert.not_contains_value(enemy3, mission:getValidEnemies())
            assert.not_contains_value(enemy4, mission:getValidEnemies())
            assert.not_contains_value(enemy5, mission:getValidEnemies())
            assert.contains_value(enemy1, mission:getInvalidEnemies())
            assert.contains_value(enemy2, mission:getInvalidEnemies())
            assert.contains_value(enemy3, mission:getInvalidEnemies())
            assert.contains_value(enemy4, mission:getInvalidEnemies())
            assert.contains_value(enemy5, mission:getInvalidEnemies())
        end)
        it("should not allow to manipulate the tables", function()
            local enemy1 = SpaceStation()
            local enemy2 = CpuShip()
            local enemy3 = CpuShip()
            local mission = Missions:destroy({enemy1, enemy2})

            local enemies = mission:getEnemies()
            table.insert(enemies, enemy3)

            assert.is_same(2, mission:countEnemies())
            assert.not_contains_value(enemy3, mission:getEnemies())
        end)
        it("returns nil it it is called before the ships are created in the callback", function()
            local enemy1 = SpaceStation()
            local enemy2 = CpuShip()
            local enemy3 = CpuShip()
            local mission = Missions:destroy(function () return {enemy1, enemy2, enemy3} end)

            assert.is_nil(mission:countEnemies())
            assert.is_nil(mission:countValidEnemies())
            assert.is_nil(mission:countInvalidEnemies())
            assert.is_nil(mission:getEnemies())
            assert.is_nil(mission:getValidEnemies())
            assert.is_nil(mission:getInvalidEnemies())
        end)
    end)

    describe("onDestruction()", function()
        it("is called each time an enemy is destroyed", function()
            local enemy1 = SpaceStation()
            local enemy2 = CpuShip()
            local enemy3 = CpuShip()
            local enemy4 = WarpJammer()
            local enemy5 = ScanProbe()
            local callback1Called = 0
            local callback2Called = 0
            local callback3Called = 0
            local callback4Called = 0
            local callback5Called = 0
            local mission
            mission = Missions:destroy({enemy1, enemy2, enemy3, enemy4, enemy5}, {onDestruction = function(callMission, callEnemy)
                assert.is_same(mission, callMission)
                if callEnemy == enemy1 then callback1Called = callback1Called + 1 end
                if callEnemy == enemy2 then callback2Called = callback2Called + 1 end
                if callEnemy == enemy3 then callback3Called = callback3Called + 1 end
                if callEnemy == enemy4 then callback4Called = callback4Called + 1 end
                if callEnemy == enemy5 then callback5Called = callback5Called + 1 end
            end})

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(0, callback1Called)
            assert.is_same(0, callback2Called)
            assert.is_same(0, callback3Called)
            assert.is_same(0, callback4Called)
            assert.is_same(0, callback5Called)

            enemy1:destroy()
            Cron.tick(1)
            assert.is_same(1, callback1Called)
            assert.is_same(0, callback2Called)
            assert.is_same(0, callback3Called)
            assert.is_same(0, callback4Called)
            assert.is_same(0, callback5Called)

            enemy2:destroy()
            enemy3:destroy()
            Cron.tick(1)
            assert.is_same(1, callback1Called)
            assert.is_same(1, callback2Called)
            assert.is_same(1, callback3Called)
            assert.is_same(0, callback4Called)
            assert.is_same(0, callback5Called)

            enemy4:destroy()
            enemy5:destroy()
            Cron.tick(1)
            assert.is_same(1, callback1Called)
            assert.is_same(1, callback2Called)
            assert.is_same(1, callback3Called)
            assert.is_same(1, callback4Called)
            assert.is_same(1, callback5Called)
        end)
    end)

    describe("onApproach()", function()
        it("is called when the player first enters 10u around the enemy", function()
            local onApproachCalled = 0
            local enemy = SpaceStation()
            local mission
            mission = Missions:destroy(enemy, {onApproach = function(callMission, callEnemy)
                assert.is_same(mission, callMission)
                assert.is_same(enemy, callEnemy)
                onApproachCalled = onApproachCalled + 1
            end})

            player:setPosition(20000, 0)
            enemy:setPosition(0, 0)

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
        it("is called when the player first gets closer than 10u to any enemy", function()
            local onApproachCalled = 0
            local enemy1 = SpaceStation()
            local enemy2 = SpaceStation()
            local mission
            mission = Missions:destroy({enemy1, enemy2}, {onApproach = function(callMission, callEnemy)
                assert.is_same(mission, callMission)
                assert.is_same(enemy2, callEnemy)
                onApproachCalled = onApproachCalled + 1
            end})

            enemy1:setPosition(0, 0)
            enemy2:setPosition(1000, 0)

            mission:setPlayer(player)
            mission:accept()
            mission:start()

            player:setPosition(11001, 0)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(0, onApproachCalled)

            player:setPosition(10999, 0)
            Cron.tick(1)
            assert.is_same(1, onApproachCalled)

            player:setPosition(9999, 0)
            Cron.tick(1)
            assert.is_same(1, onApproachCalled)
        end)
    end)

    it("successful mission", function()
        local enemy1 = SpaceStation()
        local enemy2 = CpuShip()
        local enemy3 = CpuShip()
        local mission
        mission = Missions:destroy({enemy1, enemy2, enemy3})

        mission:setPlayer(player)
        mission:accept()
        mission:start()

        Cron.tick(1)
        enemy1:destroy()
        Cron.tick(1)
        assert.is_same("started", mission:getState())
        Cron.tick(1)
        enemy2:destroy()
        Cron.tick(1)
        assert.is_same("started", mission:getState())
        Cron.tick(1)
        enemy3:destroy()
        Cron.tick(1)
        assert.is_same("successful", mission:getState())
    end)
end)