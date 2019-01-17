insulate("Missions", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local player = PlayerSpaceship()

    describe("destroyRagingMiner()", function()
        it("should create a valid Mission with one ship", function()
            local mission = Missions:destroyRagingMiner(CpuShip())

            assert.is_true(Mission:isMission(mission))
        end)
        it("fails if the first parameter is a person", function()
            assert.has_error(function() Missions:destroyRagingMiner(personMock()) end)
        end)
        it("fails if the first parameter is a table where one item is a person", function()
            assert.has_error(function() Missions:destroyRagingMiner({CpuShip(), CpuShip(), personMock()}) end)
        end)
        it("fails if the first parameter is not given", function()
            assert.has_error(function() Missions:destroyRagingMiner() end)
        end)

        it("should create a valid Mission if a callback function is given that returns one ship", function()
            local ship = CpuShip()
            local mission = Missions:destroyRagingMiner(function() return ship end)
            assert.is_true(Mission:isMission(mission))
            mission:setPlayer(player)
            mission:accept()
            mission:start()

            assert.is_same({ship}, mission:getValidEnemies())
        end)
        it("should create a valid Mission if a callback function is given that returns multiple ships", function()
            local mission = Missions:destroyRagingMiner(function() return {CpuShip(), CpuShip(), CpuShip()} end)
            assert.is_true(Mission:isMission(mission))
            mission:setPlayer(player)
            mission:accept()
            mission:start()
        end)
        it("fails if a call back function is given, but returns a person", function()
            assert.has_error(function()
                Missions:destroyRagingMiner(function() return personMock() end)
                mission:setPlayer(player)
                mission:accept()
                mission:start()
            end)
        end)
        it("fails if a call back function is given, but returns a table where one item is a person", function()
            assert.has_error(function()
                Missions:destroyRagingMiner(function() return {CpuShip(), CpuShip(), personMock()} end)
                mission:setPlayer(player)
                mission:accept()
                mission:start()
            end)
        end)
        it("fails if a call back function is given that returns nil", function()
            assert.has_error(function()
                Missions:destroyRagingMiner(function() return nil end)
                mission:setPlayer(player)
                mission:accept()
                mission:start()
            end)
        end)

        it("fails if second parameter is a number", function()
            assert.has_error(function() Missions:destroyRagingMiner(CpuShip(), 3) end)
        end)
    end)

    describe("getValidEnemies(), countValidEnemies(), getInvalidEnemies(), countInvalidEnemies(), getEnemies(), countEnemies()", function()
        it("return correct values", function()
            local enemy1 = CpuShip()
            local enemy2 = CpuShip()
            local enemy3 = CpuShip()
            local mission = Missions:destroyRagingMiner({enemy1, enemy2, enemy3})

            assert.is_same(3, mission:countEnemies())
            assert.is_same(3, mission:countValidEnemies())
            assert.is_same(0, mission:countInvalidEnemies())
            assert.contains_value(enemy1, mission:getEnemies())
            assert.contains_value(enemy2, mission:getEnemies())
            assert.contains_value(enemy3, mission:getEnemies())
            assert.contains_value(enemy1, mission:getValidEnemies())
            assert.contains_value(enemy2, mission:getValidEnemies())
            assert.contains_value(enemy3, mission:getValidEnemies())
            assert.not_contains_value(enemy1, mission:getInvalidEnemies())
            assert.not_contains_value(enemy2, mission:getInvalidEnemies())
            assert.not_contains_value(enemy3, mission:getInvalidEnemies())

            enemy1:destroy()

            assert.is_same(3, mission:countEnemies())
            assert.is_same(2, mission:countValidEnemies())
            assert.is_same(1, mission:countInvalidEnemies())
            assert.contains_value(enemy1, mission:getEnemies())
            assert.contains_value(enemy2, mission:getEnemies())
            assert.contains_value(enemy3, mission:getEnemies())
            assert.not_contains_value(enemy1, mission:getValidEnemies())
            assert.contains_value(enemy2, mission:getValidEnemies())
            assert.contains_value(enemy3, mission:getValidEnemies())
            assert.contains_value(enemy1, mission:getInvalidEnemies())
            assert.not_contains_value(enemy2, mission:getInvalidEnemies())
            assert.not_contains_value(enemy3, mission:getInvalidEnemies())

            enemy2:destroy()
            enemy3:destroy()

            assert.is_same(3, mission:countEnemies())
            assert.is_same(0, mission:countValidEnemies())
            assert.is_same(3, mission:countInvalidEnemies())
            assert.contains_value(enemy1, mission:getEnemies())
            assert.contains_value(enemy2, mission:getEnemies())
            assert.contains_value(enemy3, mission:getEnemies())
            assert.not_contains_value(enemy1, mission:getValidEnemies())
            assert.not_contains_value(enemy2, mission:getValidEnemies())
            assert.not_contains_value(enemy3, mission:getValidEnemies())
            assert.contains_value(enemy1, mission:getInvalidEnemies())
            assert.contains_value(enemy2, mission:getInvalidEnemies())
            assert.contains_value(enemy3, mission:getInvalidEnemies())
        end)
        it("should not allow to manipulate the tables", function()
            local enemy1 = CpuShip()
            local enemy2 = CpuShip()
            local enemy3 = CpuShip()
            local mission = Missions:destroyRagingMiner({enemy1, enemy2})

            local enemies = mission:getEnemies()
            table.insert(enemies, enemy3)

            assert.is_same(2, mission:countEnemies())
            assert.not_contains_value(enemy3, mission:getEnemies())
        end)
        it("returns nil it it is called before the ships are created in the callback", function()
            local enemy1 = CpuShip()
            local enemy2 = CpuShip()
            local enemy3 = CpuShip()
            local mission = Missions:destroyRagingMiner(function () return {enemy1, enemy2, enemy3} end)

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
            local enemy1 = CpuShip()
            local enemy2 = CpuShip()
            local enemy3 = CpuShip()
            local callback1Called = 0
            local callback2Called = 0
            local callback3Called = 0
            local mission
            mission = Missions:destroyRagingMiner({enemy1, enemy2, enemy3}, {onDestruction = function(callMission, callEnemy)
                assert.is_same(mission, callMission)
                if callEnemy == enemy1 then callback1Called = callback1Called + 1 end
                if callEnemy == enemy2 then callback2Called = callback2Called + 1 end
                if callEnemy == enemy3 then callback3Called = callback3Called + 1 end
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

            enemy1:destroy()
            Cron.tick(1)
            assert.is_same(1, callback1Called)
            assert.is_same(0, callback2Called)
            assert.is_same(0, callback3Called)

            enemy2:destroy()
            enemy3:destroy()
            Cron.tick(1)
            assert.is_same(1, callback1Called)
            assert.is_same(1, callback2Called)
            assert.is_same(1, callback3Called)
        end)
    end)

    it("successful mission", function()
        local enemy1 = CpuShip()
        local enemy2 = CpuShip()
        local enemy3 = CpuShip()
        local mission
        mission = Missions:destroyRagingMiner({enemy1, enemy2, enemy3})

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