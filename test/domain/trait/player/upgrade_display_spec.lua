insulate("Player", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("withUpgradeDisplay()", function()
        it("creates a valid upgrade display", function()
            local player = eePlayerMock()
            Player:withUpgradeTracker(player)
            Player:withUpgradeDisplay(player)

            assert.is_true(Player:hasUpgradeDisplay(player))
        end)

        it("fails if the first argument is not a player", function()
            assert.has_error(function() Player:withUpgradeDisplay(42) end)
        end)

        it("fails if the first argument is a player without storage", function()
            assert.has_error(function() Player:withUpgradeDisplay(eePlayerMock()) end)
        end)

        it("fails if the first argument is already an upgrade display player", function()
            local player = eePlayerMock()
            Player:withUpgradeTracker(player)
            Player:withUpgradeDisplay(player)

            assert.has_error(function() Player:withUpgradeDisplay(player) end)
        end)
    end)
end)