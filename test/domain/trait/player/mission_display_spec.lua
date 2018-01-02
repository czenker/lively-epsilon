insulate("Player", function()
    require "lively_epsilon"
    require "test.mocks"

    describe("withMissionDisplay()", function()
        it("creates a valid mission display", function()
            local player = eePlayerMock()
            Player:withMissionTracker(player)
            Player:withMissionDisplay(player)

            assert.is_true(Player:hasMissionDisplay(player))
        end)

        it("fails if the first argument is not a player", function()
            assert.has_error(function() Player:withMissionDisplay(42) end)
        end)

        it("fails if the first argument is a player without MissionTracker is not a player", function()
            assert.has_error(function() Player:withMissionDisplay(eePlayerMock()) end)
        end)

        it("fails if the first argument is already a mission display player", function()
            local player = eePlayerMock()
            Player:withMissionTracker(player)
            Player:withMissionDisplay(player)

            assert.has_error(function() Player:withMissionDisplay(player) end)
        end)
    end)
end)