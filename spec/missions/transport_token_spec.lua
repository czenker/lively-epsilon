insulate("Missions", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe("transportToken()", function()
        it("should create a valid Mission", function()
            local from = SpaceStation()
            local to = SpaceStation()
            local mission = Missions:transportToken(from, to)

            assert.is_true(Mission:isMission(mission))
        end)
        it("fails if first parameter is not a station", function()
            local from = CpuShip()
            local to = SpaceStation()
            assert.has_error(function() Missions:transportToken(from, to) end)
        end)
        it("fails if second parameter is not a station", function()
            local from = SpaceStation()
            local to = CpuShip()
            assert.has_error(function() Missions:transportToken(from, to) end)
        end)
        it("fails if third parameter is a number", function()
            local from = SpaceStation()
            local to = SpaceStation()
            assert.has_error(function() Missions:transportToken(from, to, 3) end)
        end)

        it("fails to start if mission is not a broker mission", function()
            local from = SpaceStation()
            local to = SpaceStation()
            local mission = Missions:transportToken(from, to)

            assert.has_error(function() mission:accept() end)
        end)

        it("successful mission", function()
            local onLoadCalled = false
            local onUnloadCalled = false

            local from = SpaceStation()
            local to = SpaceStation()
            local player = PlayerSpaceship()
            local mission = Missions:transportToken(from, to, {
                onLoad = function() onLoadCalled = true end,
                onUnload = function() onUnloadCalled = true end,
            })
            Mission:withBroker(mission, "Dummy")

            mission:setPlayer(player)
            mission:setMissionBroker(from)
            mission:accept()
            mission:start()

            player.isDocked = function()
                return false
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(mission:isTokenLoaded())
            assert.is_false(onLoadCalled)
            assert.is_false(onUnloadCalled)

            player.isDocked = function(self, thing)
                return thing == from
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_true(mission:isTokenLoaded())
            assert.is_true(onLoadCalled)
            assert.is_false(onUnloadCalled)

            player.isDocked = function(self, thing)
                return thing == to
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(mission:isTokenLoaded())
            assert.is_true(onLoadCalled)
            assert.is_true(onUnloadCalled)

            assert.is_same("successful", mission:getState())

        end)
    end)
end)