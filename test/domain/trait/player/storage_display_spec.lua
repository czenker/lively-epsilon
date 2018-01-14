insulate("Player", function()
    require "lively_epsilon"
    require "test.mocks"

    describe("withStorageDisplay()", function()
        it("creates a valid storage display", function()
            local player = eePlayerMock()
            Player:withStorage(player)
            Player:withStorageDisplay(player)

            assert.is_true(Player:hasStorageDisplay(player))
        end)

        it("fails if the first argument is not a player", function()
            assert.has_error(function() Player:withStorageDisplay(42) end)
        end)

        it("fails if the first argument is a player without storage", function()
            local player = eePlayerMock()

            assert.has_error(function() Player:withStorageDisplay(player) end)
        end)

        it("fails if the first argument is already a storage display player", function()
            local player = eePlayerMock()
            Player:withStorage(player)
            Player:withStorageDisplay(player)

            assert.has_error(function() Player:withStorageDisplay(player) end)
        end)
    end)
end)