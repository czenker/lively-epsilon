insulate("Player", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local defaultConfig = {
        label = "Missions",
        titleActiveMissions = "Active Missions",
        noActiveMissions = "You have no active missions",
    }

    describe("withMissionDisplay()", function()
        it("creates a valid mission display", function()
            local player = PlayerSpaceship()
            Player:withMenu(player)
            Player:withMissionTracker(player)
            Player:withMissionDisplay(player, defaultConfig)

            assert.is_true(Player:hasMissionDisplay(player))

            assert.is_true(player:hasButton("relay", "Missions"))
            player:clickButton("relay", "Missions")
            assert.is_true(player:hasCustomMessage("relay"))
        end)

        it("fails if the first argument is not a player", function()
            assert.has_error(function() Player:withMissionDisplay(42, defaultConfig) end)
        end)

        it("fails if the first argument is a player without storage", function()
            assert.has_error(function() Player:withMissionDisplay(PlayerSpaceship(), defaultConfig) end)
        end)

        it("fails if the first argument is already a mission display player", function()
            local player = PlayerSpaceship()
            Player:withMenu(player)
            Player:withMissionTracker(player)
            Player:withMissionDisplay(player, defaultConfig)

            assert.has_error(function() Player:withMissionDisplay(player, defaultConfig) end)
        end)
    end)
end)