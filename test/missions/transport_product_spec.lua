insulate("Missions", function()

    require "lively_epsilon"
    require "test.mocks"

    describe("transportProduct()", function()
        local from = eeStationMock()
        local to = eeStationMock()
        local product = productMock()
        it("should create a valid Mission", function()
            local mission = Missions:transportProduct(from, to, product)
            assert.is_true(Mission.isMission(mission))
        end)
        it("fails if first parameter is not a station", function()
            local from = eeCpuShipMock()
            assert.has_error(function() Missions:transportProduct(from, to, product) end)
        end)
        it("fails if second parameter is not a station", function()
            assert.has_error(function() Missions:transportProduct(from, eeCpuShipMock, product) end)
        end)
        it("fails if third parameter is a number", function()
            assert.has_error(function() Missions:transportProduct(from, to, 3) end)
        end)
        it("fails if fourth parameter is a number", function()
            assert.has_error(function() Missions:transportProduct(from, to, product, 3) end)
        end)

        it("fails to start if mission is not a broker mission", function()
            local mission = Missions:transportProduct(from, to, product)
            mission:accept()
            assert.has_error(function() mission:start() end)
        end)

        it("successful mission", function()
            local onLoadCalled = false
            local onUnloadCalled = false
            local player = eePlayerMock()
            local mission
            mission = Missions:transportProduct(from, to, product, {
                amount = 42,
                onLoad = function(theMission)
                    assert.is_same(mission, theMission)
                    onLoadCalled = true
                end,
                onUnload = function(theMission)
                    assert.is_same(mission, theMission)
                    onUnloadCalled = true
                end,
            })
            Mission:withBroker(mission, "Dummy")

            mission:setPlayer(player)
            Player:withStorage(player, {maxStorage=100})
            mission:setMissionBroker(from)
            mission:accept()
            mission:start()

            player.isDocked = function()
                return false
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(mission:isLoaded())
            assert.is_false(onLoadCalled)
            assert.is_false(onUnloadCalled)
            assert.is_same(0, player:getProductStorage(product))

            player.isDocked = function(self, thing)
                return thing == from
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_true(mission:isLoaded())
            assert.is_true(onLoadCalled)
            assert.is_false(onUnloadCalled)
            assert.is_same(42, player:getProductStorage(product))

            player.isDocked = function()
                return false
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)

            player.isDocked = function(self, thing)
                return thing == to
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(mission:isLoaded())
            assert.is_true(onLoadCalled)
            assert.is_true(onUnloadCalled)
            assert.is_same(0, player:getProductStorage(product))

            assert.is_same("successful", mission:getState())
        end)
        it("fails when product is sold or lost", function()
            local onProductLostCalled = false
            local player = eePlayerMock()
            Player:withStorage(player, {maxStorage=100})

            local mission
            mission = Missions:transportProduct(from, to, product, {
                amount = 42,
                onProductLost = function(theMission)
                    assert.is_same(mission, theMission)
                    onProductLostCalled = true
                end,
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
            assert.is_false(mission:isLoaded())
            assert.is_false(onProductLostCalled)

            player.isDocked = function(self, thing)
                return thing == from
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_true(mission:isLoaded())
            assert.is_false(onProductLostCalled)

            player:modifyProductStorage(product, -10)

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(mission:isLoaded())
            assert.is_true(onProductLostCalled)
            assert.is_same(32, player:getProductStorage(product))

            assert.is_same("failed", mission:getState())
        end)
        it("calls onInsufficientStorage if the player ship has no storage as soon as the player docks", function()
            local onInsufficientStorageCalled = 0
            local player = eePlayerMock()

            local mission
            mission = Missions:transportProduct(from, to, product, {
                onInsufficientStorage = function(theMission)
                    assert.is_same(mission, theMission)
                    onInsufficientStorageCalled = onInsufficientStorageCalled + 1
                end,
            })
            Mission:withBroker(mission, "Dummy")

            mission:setPlayer(player)
            mission:setMissionBroker(from)
            mission:accept()
            mission:start()

            player.isDocked = function(self, thing)
                return thing == from
            end

            Cron.tick(1)
            assert.is_same(1, onInsufficientStorageCalled)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, onInsufficientStorageCalled)
        end)
        it("calls onInsufficientStorage if the player has not enough storage as soon as the player docks", function()
            local onInsufficientStorageCalled = 0
            local player = eePlayerMock()

            local mission
            mission = Missions:transportProduct(from, to, product, {
                onInsufficientStorage = function(theMission)
                    assert.is_same(mission, theMission)
                    onInsufficientStorageCalled = onInsufficientStorageCalled + 1
                end,
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
            assert.is_same(0, onInsufficientStorageCalled)

            player.isDocked = function(self, thing)
                return thing == from
            end

            Cron.tick(1)
            assert.is_same(1, onInsufficientStorageCalled)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, onInsufficientStorageCalled)

            player.isDocked = function()
                return false
            end

            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, onInsufficientStorageCalled)

            player.isDocked = function(self, thing)
                return thing == from
            end

            Cron.tick(1)
            assert.is_same(2, onInsufficientStorageCalled)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(2, onInsufficientStorageCalled)
        end)
    end)
end)