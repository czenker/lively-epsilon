insulate("Player", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local defaultConfig = {
        label = "Presets",
        labelLoad = "Load",
        labelStore = "Store",
        labelLoadItem = "Load",
        labelStoreItem = "Store",
    }

    describe("withPowerPresets()", function()
        it("works with default parameters", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {backLabel = "Back"})
            Player:withPowerPresets(player, Util.mergeTables(defaultConfig, { slots = 4 }))
            assert.is_true(Player:hasPowerPresets(player))

            assert.is_true(player:hasButton("engineering", "Presets"))
            player:clickButton("engineering", "Presets")
            assert.is_true(player:hasButton("engineering", "Load"))
            assert.is_true(player:hasButton("engineering", "Store"))
            player:clickButton("engineering", "Store")
            assert.is_true(player:hasButton("engineering", "Store 1"))
            assert.is_true(player:hasButton("engineering", "Store 2"))
            assert.is_true(player:hasButton("engineering", "Store 3"))
            assert.is_true(player:hasButton("engineering", "Store 4"))
            assert.is_false(player:hasButton("engineering", "Store 5"))

            player:setSystemPower("impulse", 0.5)
            player:setSystemCoolant("impulse", 0.42)
            player:clickButton("engineering", "Store 1")
            player:clickButton("engineering", "Back")

            player:setSystemPower("impulse", 1)
            player:setSystemCoolant("impulse", 0)
            player:clickButton("engineering", "Presets")
            player:clickButton("engineering", "Load")
            assert.is_true(player:hasButton("engineering", "Load 1"))
            assert.is_true(player:hasButton("engineering", "Load 2"))
            assert.is_true(player:hasButton("engineering", "Load 3"))
            assert.is_true(player:hasButton("engineering", "Load 4"))
            assert.is_false(player:hasButton("engineering", "Load 5"))

            player:clickButton("engineering", "Load 1")

            assert.is_same(0.5, player:getSystemPower("impulse"))
            assert.is_same(0.42, player:getSystemCoolant("impulse"))
        end)
        it("can add a reset button", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {backLabel = "Back"})
            Player:withPowerPresets(player, Util.mergeTables(defaultConfig, { labelReset = "Reset" }))
            assert.is_true(Player:hasPowerPresets(player))

            player:clickButton("engineering", "Presets")
            assert.is_true(player:hasButton("engineering", "Reset"))

            player:setSystemPower("impulse", 2)
            player:setSystemCoolant("impulse", 1)
            player:clickButton("engineering", "Reset")
            assert.is_same(1, player:getSystemPower("impulse"))
            assert.is_same(0, player:getSystemCoolant("impulse"))
        end)
        it("can add an info button", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {backLabel = "Back"})
            Player:withPowerPresets(player, Util.mergeTables(defaultConfig, { labelInfo = "Info", infoText = "Hello World" }))
            assert.is_true(Player:hasPowerPresets(player))

            player:clickButton("engineering", "Presets")
            assert.is_true(player:hasButton("engineering", "Info"))
            player:clickButton("engineering", "Info")
            assert.is_same("Hello World", player:getCustomMessage("engineering"))
        end)
    end)
end)