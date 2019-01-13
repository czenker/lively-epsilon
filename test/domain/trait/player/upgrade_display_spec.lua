insulate("Player", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local defaultConfig = {
        label = "Upgrades",
        title = "Your Upgrades",
        noUpgrades = "You have no upgrades installed.",
    }

    describe("withUpgradeDisplay()", function()
        it("creates a valid upgrade display", function()
            local player = eePlayerMock()
            Player:withMenu(player)
            Player:withUpgradeTracker(player)
            Player:withUpgradeDisplay(player, defaultConfig)

            assert.is_true(Player:hasUpgradeDisplay(player))

            assert.is_true(player:hasButton("engineering", "Upgrades"))
            player:clickButton("engineering", "Upgrades")
            assert.is_true(player:hasCustomMessage("engineering"))
        end)

        it("fails if the first argument is not a player", function()
            assert.has_error(function() Player:withUpgradeDisplay(42, defaultConfig) end)
        end)

        it("fails if the first argument is a player without storage", function()
            assert.has_error(function() Player:withUpgradeDisplay(eePlayerMock(), defaultConfig) end)
        end)

        it("fails if the first argument is already an upgrade display player", function()
            local player = eePlayerMock()
            Player:withMenu(player)
            Player:withUpgradeTracker(player)
            Player:withUpgradeDisplay(player, defaultConfig)

            assert.has_error(function() Player:withUpgradeDisplay(player, defaultConfig) end)
        end)
    end)
end)