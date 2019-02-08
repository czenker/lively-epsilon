insulate("Player:withStorageDisplay()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local defaultConfig = {
        label = "Storage",
        title = "Your Storage",
        labelUsedStorage = "Used Storage",
        emptyStorage = "Your storage is empty.",
    }

    it("creates a valid storage display", function()
        local player = PlayerSpaceship()
        Player:withMenu(player)
        Player:withStorage(player)
        Player:withStorageDisplay(player, defaultConfig)

        assert.is_true(Player:hasStorageDisplay(player))

        assert.is_true(player:hasButton("engineering", "Storage"))
        player:clickButton("engineering", "Storage")
        assert.is_true(player:hasCustomMessage("engineering"))
    end)

    it("fails if the first argument is not a player", function()
        assert.has_error(function() Player:withStorageDisplay(42, defaultConfig) end)
    end)

    it("fails if the first argument is a player without storage", function()
        local player = PlayerSpaceship()

        assert.has_error(function() Player:withStorageDisplay(player, defaultConfig) end)
    end)

    it("fails if the first argument is already a storage display player", function()
        local player = PlayerSpaceship()
        Player:withMenu(player)
        Player:withStorage(player)
        Player:withStorageDisplay(player, defaultConfig)

        assert.has_error(function() Player:withStorageDisplay(player, defaultConfig) end)
    end)
end)