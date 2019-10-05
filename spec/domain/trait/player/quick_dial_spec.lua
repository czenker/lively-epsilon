insulate("Player:withQuickDial()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local defaultConfig = {
        label = "Quick Dial",
    }

    it("works with default parameters", function()
        local player = PlayerSpaceship()
        Player:withMenu(player, {backLabel = "Back"})
        Player:withQuickDial(player, defaultConfig)
        assert.is_true(Player:hasQuickDial(player))

        assert.is_true(player:hasButton("relay", "Quick Dial"))
        player:clickButton("relay", "Quick Dial")
        player:clickButton("relay", "Back")
    end)
    describe(":addQuickDial()", function()
        it("allows to add stations", function()
            local player = PlayerSpaceship()
            local station = SpaceStation():setCallSign("Outpost 42")
            Player:withMenu(player, {backLabel = "Back"})
            Player:withQuickDial(player, defaultConfig)
            assert.is_true(Player:hasQuickDial(player))

            player:addQuickDial(station)

            assert.is_true(player:hasButton("relay", "Quick Dial"))
            player:clickButton("relay", "Quick Dial")
            assert.is_true(player:hasButton("relay", "Outpost 42"))
        end)
        it("allows to add ships", function()
            local player = PlayerSpaceship()
            local ship = CpuShip():setCallSign("Nostromo")
            Player:withMenu(player, {backLabel = "Back"})
            Player:withQuickDial(player, defaultConfig)
            assert.is_true(Player:hasQuickDial(player))

            player:addQuickDial(ship)

            assert.is_true(player:hasButton("relay", "Quick Dial"))
            player:clickButton("relay", "Quick Dial")
            assert.is_true(player:hasButton("relay", "Nostromo"))
        end)
        it("allows to add fleets", function()
            local player = PlayerSpaceship()
            local fleet = Fleet:new({
                CpuShip():setCallSign("Fleet Leader"),
                CpuShip():setCallSign("Wingman")
            })
            Player:withMenu(player, {backLabel = "Back"})
            Player:withQuickDial(player, defaultConfig)
            assert.is_true(Player:hasQuickDial(player))

            player:addQuickDial(fleet)

            assert.is_true(player:hasButton("relay", "Quick Dial"))
            player:clickButton("relay", "Quick Dial")
            assert.is_true(player:hasButton("relay", "Fleet Leader"))
        end)

        it("fails when adding an invalid thing", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {backLabel = "Back"})
            Player:withQuickDial(player, defaultConfig)
            assert.is_true(Player:hasQuickDial(player))

            assert.has_error(function()
                player:addQuickDial()
            end)
            assert.has_error(function()
                player:addQuickDial(42)
            end)
            assert.has_error(function()
                player:addQuickDial(Asteroid())
            end)
        end)
    end)
    describe(":removeQuickDial()", function()
        it("allows to remove a quick dial", function()
            local player = PlayerSpaceship()
            local station = SpaceStation():setCallSign("Outpost 42")
            Player:withMenu(player, {backLabel = "Back"})
            Player:withQuickDial(player, defaultConfig)
            assert.is_true(Player:hasQuickDial(player))

            player:addQuickDial(CpuShip())
            player:addQuickDial(CpuShip())
            player:addQuickDial(station)
            player:addQuickDial(CpuShip())

            assert.is_true(player:hasButton("relay", "Quick Dial"))
            player:clickButton("relay", "Quick Dial")
            assert.is_true(player:hasButton("relay", "Outpost 42"))
            player:clickButton("relay", "Back")

            player:removeQuickDial(station)
            player:clickButton("relay", "Quick Dial")
            assert.is_false(player:hasButton("relay", "Outpost 42"))
        end)
    end)
    describe("getQuickDials()", function()
        it("returns a table with all added quick dials", function()
            local player = PlayerSpaceship()
            local station = SpaceStation():setCallSign("Outpost 42")
            local fleet = Fleet:new({
                CpuShip():setCallSign("Fleet Leader"),
                CpuShip():setCallSign("Wingman")
            })
            local ship = CpuShip():setCallSign("Nostromo")
            Player:withMenu(player, {backLabel = "Back"})
            Player:withQuickDial(player, defaultConfig)
            assert.is_true(Player:hasQuickDial(player))

            assert.not_contains_value(station, player:getQuickDials())
            assert.not_contains_value(fleet, player:getQuickDials())
            assert.not_contains_value(ship, player:getQuickDials())

            player:addQuickDial(station)

            assert.contains_value(station, player:getQuickDials())

            player:addQuickDial(fleet)
            player:addQuickDial(ship)

            assert.contains_value(fleet, player:getQuickDials())
            assert.contains_value(ship, player:getQuickDials())

            player:removeQuickDial(station)

            assert.not_contains_value(station, player:getQuickDials())
            assert.contains_value(fleet, player:getQuickDials())
            assert.contains_value(ship, player:getQuickDials())
        end)
        it("does not return invalid entities", function()
            local player = PlayerSpaceship()
            local station = SpaceStation():setCallSign("Outpost 42")
            local fleet = Fleet:new({
                CpuShip():setCallSign("Fleet Leader"),
                CpuShip():setCallSign("Wingman")
            })
            local ship = CpuShip():setCallSign("Nostromo")
            Player:withMenu(player, {backLabel = "Back"})
            Player:withQuickDial(player, defaultConfig)
            assert.is_true(Player:hasQuickDial(player))

            player:addQuickDial(station)
            player:addQuickDial(fleet)
            player:addQuickDial(ship)

            assert.contains_value(station, player:getQuickDials())
            assert.contains_value(fleet, player:getQuickDials())
            assert.contains_value(ship, player:getQuickDials())

            ship:destroy()

            assert.contains_value(station, player:getQuickDials())
            assert.contains_value(fleet, player:getQuickDials())
            assert.not_contains_value(ship, player:getQuickDials())

            station:destroy()

            assert.not_contains_value(station, player:getQuickDials())
            assert.contains_value(fleet, player:getQuickDials())
            assert.not_contains_value(ship, player:getQuickDials())
        end)
    end)
    it("ignores invalid stations", function()
        local player = PlayerSpaceship()
        local station = SpaceStation():setCallSign("Outpost 42")
        Player:withMenu(player, {backLabel = "Back"})
        Player:withQuickDial(player, defaultConfig)
        assert.is_true(Player:hasQuickDial(player))

        player:addQuickDial(station)

        station:destroy()

        assert.is_true(player:hasButton("relay", "Quick Dial"))
        player:clickButton("relay", "Quick Dial")
        assert.is_false(player:hasButton("relay", "Outpost 42"))
    end)
end)