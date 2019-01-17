insulate("Player", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("withUpgradeTracker()", function()
        it("creates a valid upgrade tracker", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            assert.is_true(Player:hasUpgradeTracker(player))
        end)

        it("fails if the first argument is not a player", function()
            assert.has_error(function() Player:withUpgradeTracker(42) end)
        end)

        it("fails if the first argument is already an upgrade tracker player", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            assert.has_error(function() Player:withUpgradeTracker(player) end)
        end)
    end)

    describe("addUpgrade()", function()
        it("adds a upgrade", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            local upgrade = upgradeMock()

            player:addUpgrade(upgrade)

            assert.is_same(1, Util.size(player:getUpgrades()))
        end)

        it("fails if the first parameter is not a upgrade", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            assert.has_error(function() player:addUpgrade(42) end)
        end)
    end)

    describe("getUpgrades()", function()
        it("returns all upgrades", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            player:addUpgrade(upgradeMock())
            player:addUpgrade(upgradeMock())
            player:addUpgrade(upgradeMock())

            assert.is_same(3, Util.size(player:getUpgrades()))
        end)

        it("manipulating the result set does not add upgrades", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            player:addUpgrade(upgradeMock())

            local upgrades = player:getUpgrades()
            table.insert(upgrades, upgradeMock())

            assert.is_same(1, Util.size(player:getUpgrades()))
        end)
    end)

    describe("hasUpgrade()", function()
        it("returns false if the upgrade is not installed by object", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            player:addUpgrade(upgradeMock())
            player:addUpgrade(upgradeMock())

            assert.is_false(player:hasUpgrade(upgradeMock()))
        end)
        it("returns false if the upgrade is not installed by name", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            player:addUpgrade(upgradeMock())
            player:addUpgrade(upgradeMock())

            assert.is_false(player:hasUpgrade("fake"))
        end)
        it("returns true if the upgrade is installed by object", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            player:addUpgrade(upgradeMock())
            player:addUpgrade(upgradeMock())

            local upgrade = upgradeMock()
            player:addUpgrade(upgrade)

            assert.is_true(player:hasUpgrade(upgrade))
        end)
        it("returns false if the upgrade is not installed by name", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            player:addUpgrade(upgradeMock())
            player:addUpgrade(upgradeMock())

            local upgrade = upgradeMock()
            player:addUpgrade(upgrade)

            assert.is_true(player:hasUpgrade(upgrade:getId()))
        end)
        it("fails if the given argument is a number", function()
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            player:addUpgrade(upgradeMock())

            assert.has_error(function() player:hasUpgrade(42) end)
        end)
    end)

end)