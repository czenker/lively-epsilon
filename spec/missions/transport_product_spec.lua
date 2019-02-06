insulate("Missions", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe(":transportProduct()", function()
        local from = SpaceStation()
        local to = SpaceStation()
        local product = productMock()
        it("should create a valid Mission", function()
            local mission = Missions:transportProduct(from, to, product)
            assert.is_true(Mission:isMission(mission))
        end)
        it("fails if first parameter is not a station", function()
            local from = CpuShip()
            assert.has_error(function() Missions:transportProduct(from, to, product) end)
        end)
        it("fails if second parameter is not a station", function()
            assert.has_error(function() Missions:transportProduct(from, CpuShip, product) end)
        end)
        it("fails if third parameter is a number", function()
            assert.has_error(function() Missions:transportProduct(from, to, 3) end)
        end)
        it("fails if fourth parameter is a number", function()
            assert.has_error(function() Missions:transportProduct(from, to, product, 3) end)
        end)

        it("fails to accept if mission is not a broker mission", function()
            local mission = Missions:transportProduct(from, to, product)
            assert.has_error(function() mission:accept() end)
        end)

        it("fails to accept if the player ship has no storage at all", function()
            local acceptConditionCalled = false
            local player = PlayerSpaceship()
            local mission
            mission = Missions:transportProduct(from, to, product, {
                acceptCondition = function(theMission, theError)
                    assert.is_same(mission, theMission)
                    assert.is_same("no_storage", theError)
                    acceptConditionCalled = true
                    return "You have no storage"
                end
            })
            Mission:withBroker(mission, "Dummy")

            mission:setPlayer(player)
            mission:setMissionBroker(from)

            local success, message = mission:canBeAccepted()
            assert.is_true(acceptConditionCalled)
            assert.is_false(success)
            assert.is_same("You have no storage", message)

            assert.has_error(function() mission:accept() end)
        end)

        it("fails to accept if the player ship has too little storage even if they removed everything", function()
            local acceptConditionCalled = false
            local player = PlayerSpaceship()
            local mission
            mission = Missions:transportProduct(from, to, product, {
                amount = 42,
                acceptCondition = function(theMission, theError)
                    assert.is_same(mission, theMission)
                    assert.is_same("small_storage", theError)
                    acceptConditionCalled = true
                    return "You have too little storage"
                end,
            })
            Mission:withBroker(mission, "Dummy")

            mission:setPlayer(player)
            Player:withStorage(player, {maxStorage=40})
            mission:setMissionBroker(from)

            local success, message = mission:canBeAccepted()
            assert.is_true(acceptConditionCalled)
            assert.is_false(success)
            assert.is_same("You have too little storage", message)

            assert.has_error(function() mission:accept() end)
        end)

        it("successful mission", function()
            local onLoadCalled = false
            local onUnloadCalled = false
            local player = PlayerSpaceship()
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
            local player = PlayerSpaceship()
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
            local player = PlayerSpaceship()

            local mission
            mission = Missions:transportProduct(from, to, product, {
                amount = 42,
                onInsufficientStorage = function(theMission)
                    assert.is_same(mission, theMission)
                    onInsufficientStorageCalled = onInsufficientStorageCalled + 1
                end,
            })
            Mission:withBroker(mission, "Dummy")
            Player:withStorage(player, {maxStorage=100})

            mission:setPlayer(player)
            mission:setMissionBroker(from)
            mission:accept()
            mission:start()

            player:modifyProductStorage(product, 60)

            player.isDocked = function(self, thing)
                return thing == from
            end

            Cron.tick(1)
            assert.is_same(1, onInsufficientStorageCalled)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, onInsufficientStorageCalled)
        end)
    end)
end)