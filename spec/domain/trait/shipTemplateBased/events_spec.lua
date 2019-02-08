insulate("ShipTemplateBased:withEvents()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("fails if a number is given instead of shipTemplateBased", function()
        assert.has_error(function()
            ShipTemplateBased:withEvents(42)
        end)
    end)

    describe("config.onDestruction", function()
        it("is called when the shipTemplateBased is destroyed", function()
            local called = 0
            local station = SpaceStation()
            ShipTemplateBased:withEvents(station, {
                onDestruction = function()
                    called = called + 1
                end,
            })

            Cron.tick(1)
            assert.is_same(0, called)

            station:destroy()
            Cron.tick(1)
            assert.is_same(1, called)

            -- it is only called once
            Cron.tick(1)
            assert.is_same(1, called)
        end)

        it("is called with the destroyed shipTemplateBased", function()
            local station = SpaceStation()
            local calledArg

            ShipTemplateBased:withEvents(station, {
                onDestruction = function(arg)
                    calledArg = arg
                end,
            })

            station:destroy()
            Cron.tick(1)
            assert.is_same(station, calledArg)
        end)

        it("does not fail if the callback errors", function()
            local station = SpaceStation()
            ShipTemplateBased:withEvents(station, {
                onDestruction = function()
                    error("Boom")
                end,
            })

            station:destroy()
            assert.not_has_error(function()
                Cron.tick(1)
            end)
        end)

        it("fails if onDestruction is not a callback", function()
            local station = SpaceStation()

            assert.has_error(function()
                ShipTemplateBased:withEvents(station, { onDestruction = 42})
            end)
        end)
    end)

    describe("config.onEnemyDetection", function()
        it("does only trigger when an enemy moves into range", function()
            local called = 0
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onEnemyDetection = function()
                    called = called + 1
                end,
            })

            -- don't trigger when enemy is outside scanner range
            station:setPosition(0, 0)
            enemy:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(0, called)

            -- call when enemy moves in range
            enemy:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(1, called)

            -- does not call as long as enemy stays in range
            Cron.tick(1)
            assert.is_same(1, called)

            -- does not trigger when enemy leaves range
            enemy:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(1, called)

            -- does trigger again when enemy reenters scanner range
            enemy:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(2, called)
        end)

        it("does not trigger multiple times when multiple enemies enter and leave", function()
            local called = 0
            local station = SpaceStation()
            local enemy1 = CpuShip()
            local enemy2 = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy1) < range or distance(self, enemy2) < range
            end
            ShipTemplateBased:withEvents(station, {
                onEnemyDetection = function()
                    called = called + 1
                end,
            })

            -- don't trigger when enemies are outside scanner range
            station:setPosition(0, 0)
            enemy1:setPosition(99999, 0)
            enemy2:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(0, called)

            enemy1:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(1, called)

            -- do not trigger when second enemy enters range
            enemy2:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(1, called)

            -- do not trigger when one enemy leaves and enters again
            enemy1:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(1, called)
            enemy1:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(1, called)

            -- trigger again when ships reenter
            enemy1:setPosition(99999, 0)
            enemy2:setPosition(99999, 0)
            Cron.tick(1)

            enemy1:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(2, called)
        end)

        it("is called with the shipTemplateBased", function()
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            local calledArg

            ShipTemplateBased:withEvents(station, {
                onEnemyDetection = function(arg)
                    calledArg = arg
                end,
            })

            station:setPosition(0, 0)
            enemy:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(station, calledArg)
        end)

        it("does not fail if the callback errors", function()
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onEnemyDetection = function()
                    error("Boom")
                end,
            })
            station:setPosition(0, 0)
            enemy:setPosition(1000, 0)

            assert.not_has_error(function()
                Cron.tick(1)
            end)
        end)

        it("fails if onDestruction is not a callback", function()
            local station = SpaceStation()

            assert.has_error(function()
                ShipTemplateBased:withEvents(station, { onEnemyDetection = 42})
            end)
        end)
    end)

    describe("config.onEnemyClear", function()
        it("does only trigger when an enemy moves out of range", function()
            local called = 0
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onEnemyClear = function()
                    called = called + 1
                end,
            })

            -- don't trigger when enemy is outside scanner range
            station:setPosition(0, 0)
            enemy:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(0, called)

            -- do not call when enemy moves in range
            enemy:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(0, called)

            -- does not call as long as enemy stays in range
            Cron.tick(1)
            assert.is_same(0, called)

            -- calls when enemy leaves range
            enemy:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(1, called)

            -- does not trigger when enemy stays out of range
            Cron.tick(1)
            assert.is_same(1, called)

            -- calls when enemy leaves range again
            enemy:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(1, called)
            enemy:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(2, called)
        end)

        it("does not trigger multiple times when multiple enemies enter and leave", function()
            local called = 0
            local station = SpaceStation()
            local enemy1 = CpuShip()
            local enemy2 = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy1) < range or distance(self, enemy2) < range
            end
            ShipTemplateBased:withEvents(station, {
                onEnemyClear = function()
                    called = called + 1
                end,
            })

            -- don't trigger when enemies are outside scanner range
            station:setPosition(0, 0)
            enemy1:setPosition(99999, 0)
            enemy2:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(0, called)

            enemy1:setPosition(20000, 0)
            enemy2:setPosition(20000, 0)
            Cron.tick(1)
            assert.is_same(0, called)

            -- do not trigger when one enemy leaves range
            enemy2:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(0, called)

            -- but trigger if both leave the range
            enemy1:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(1, called)

        end)

        it("is called with the shipTemplateBased", function()
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            local calledArg

            ShipTemplateBased:withEvents(station, {
                onEnemyClear = function(arg)
                    calledArg = arg
                end,
            })

            station:setPosition(0, 0)
            enemy:setPosition(20000, 0)
            Cron.tick(1)
            enemy:setPosition(99999, 0)
            Cron.tick(1)
            assert.is_same(station, calledArg)
        end)

        it("does not fail if the callback errors", function()
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onEnemyClear = function()
                    error("Boom")
                end,
            })
            station:setPosition(0, 0)
            enemy:setPosition(1000, 0)

            assert.not_has_error(function()
                Cron.tick(1)
            end)
        end)

        it("fails if onDestruction is not a callback", function()
            local station = SpaceStation()

            assert.has_error(function()
                ShipTemplateBased:withEvents(station, { onEnemyClear = 42})
            end)
        end)
    end)

    describe("config.onBeingAttacked", function()

        it("is called when the shipTemplateBased looses shield and enemy is close", function()
            local called = 0
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onBeingAttacked = function()
                    called = called + 1
                end,
            })
            station:setHullMax(100)
            station:setHull(100)
            station:setShieldsMax(100)
            station:setShields(100)
            station:setPosition(0, 0)
            enemy:setPosition(2000, 0)

            called = 0
            Cron.tick(1)
            assert.is_same(0, called)

            station:setShields(90)
            Cron.tick(1)
            assert.is_same(1, called)

            station:setShields(80)
            Cron.tick(1)
            assert.is_same(1, called)
        end)

        it("is called when the shipTemplateBased looses hull and enemy is close", function()
            local called = 0
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onBeingAttacked = function()
                    called = called + 1
                end,
            })
            station:setHullMax(100)
            station:setHull(100)
            station:setShieldsMax(100)
            station:setShields(100)
            station:setPosition(0, 0)
            enemy:setPosition(2000, 0)

            called = 0
            Cron.tick(1)
            assert.is_same(0, called)

            station:setHull(90)
            Cron.tick(1)
            assert.is_same(1, called)

            station:setHull(80)
            Cron.tick(1)
            assert.is_same(1, called)
        end)

        it("is not called when hull or shield are damaged, but there is no enemy close", function()
            local called = 0
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onBeingAttacked = function()
                    called = called + 1
                end,
            })
            station:setHullMax(100)
            station:setHull(100)
            station:setShieldsMax(100)
            station:setShields(100)
            station:setPosition(0, 0)
            enemy:setPosition(99999, 0)

            called = 0
            Cron.tick(1)
            assert.is_same(0, called)

            station:setHull(90)
            Cron.tick(1)
            assert.is_same(0, called)

            station:setShields(90)
            Cron.tick(1)
            assert.is_same(0, called)
        end)

        it("is called after it has not received damage for 2 minutes", function()
            local called = 0
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onBeingAttacked = function()
                    called = called + 1
                end,
            })
            station:setHullMax(100)
            station:setHull(100)
            station:setShieldsMax(100)
            station:setShields(100)
            station:setPosition(0, 0)
            enemy:setPosition(2000, 0)

            called = 0
            Cron.tick(1)
            assert.is_same(0, called)

            station:setShields(90)
            Cron.tick(1)
            assert.is_same(1, called)

            for i=1,120 do Cron.tick(1) end

            station:setShields(80)
            Cron.tick(1)
            assert.is_same(2, called)
        end)

        it("is called with the shipTemplateBased", function()
            local station = SpaceStation()
            local enemy = CpuShip()
            local calledArg
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onBeingAttacked = function(arg1)
                    calledArg = arg1
                end,
            })
            station:setHullMax(100)
            station:setHull(100)
            station:setShieldsMax(100)
            station:setShields(100)
            station:setPosition(0, 0)
            enemy:setPosition(2000, 0)

            Cron.tick(1)
            station:setShields(90)
            Cron.tick(1)

            assert.is_same(station, calledArg)
        end)

        it("does not fail if the callback errors", function()
            local station = SpaceStation()
            local enemy = CpuShip()
            station.areEnemiesInRange = function(self, range)
                return distance(self, enemy) < range
            end
            ShipTemplateBased:withEvents(station, {
                onBeingAttacked = function()
                    error("Boom")
                end,
            })
            station:setHullMax(100)
            station:setHull(100)
            station:setShieldsMax(100)
            station:setShields(100)
            station:setPosition(0, 0)
            enemy:setPosition(2000, 0)

            Cron.tick(1)
            station:setShields(90)

            assert.not_has_error(function()
                Cron.tick(1)
            end)
        end)

        it("fails if onBeingAttacked is not a callback", function()
            local station = SpaceStation()

            assert.has_error(function()
                ShipTemplateBased:withEvents(station, { onBeingAttacked = 42})
            end)
        end)
    end)

end)