insulate("Player", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("withMenu()", function()
        it("creates a valid menu", function()
            local player = eePlayerMock()
            Player:withMenu(player)

            assert.is_true(Player:hasMenu(player))
        end)

        it("fails if the first argument is not a player", function()
            assert.has_error(function() Player:withMenu(42) end)
        end)

        it("fails if the first argument already has menus", function()
            local player = eePlayerMock()
            Player:withMenu(player)

            assert.has_error(function() Player:withMenu(player) end)
        end)

        it("draws submenus", function()
            -- test setup
            local player = eePlayerMock()
            Player:withMenu(player, {
                backLabel = "Back",
            })

            local submenu = mockSubmenu("Submenu", function(menu)
                menu:addItem(mockMenuLabel("You are in a submenu"))
            end)

            player:addScienceMenuItem(submenu)
            player:addScienceMenuItem(mockMenuLabel("Original Item"))
            assert.is_true(player:hasButton("science", "Submenu"))
            assert.is_true(player:hasButton("science", "Original Item"))
            assert.is_false(player:hasButton("science", "Back"))

            player:clickButton("science", "Submenu")
            assert.is_false(player:hasButton("science", "Submenu"))
            assert.is_false(player:hasButton("science", "Original Item"))
            assert.is_true(player:hasButton("science", "You are in a submenu"))

            -- there should ALWAYS! be a back button so the player can go back to the main menu
            assert.is_true(player:hasButton("science", "Back"))

            player:clickButton("science", "Back")
            assert.is_true(player:hasButton("science", "Submenu"))
            assert.is_true(player:hasButton("science", "Original Item"))
            assert.is_false(player:hasButton("science", "You are in a submenu"))
            assert.is_false(player:hasButton("science", "Back"))
        end)

        it("triggers callbacks on click", function()
            local player = eePlayerMock()
            Player:withMenu(player)

            local called, callArg1, callArg2 = 0, nil, nil
            player:addRelayMenuItem("function", Menu:newItem("Callback", function(arg1, arg2)
                called = called + 1
                callArg1 = arg1
                callArg2 = arg2
            end))

            assert.is_same(0, called)
            assert.is_nil(callArg1)
            assert.is_nil(callArg2)
            player:clickButton("relay", "Callback")
            assert.is_same(1, called)
            assert.is_same(player, callArg1)
            assert.is_same("relay", callArg2)
        end)
    end)
    describe("addHelmsMenuItem(), removeHelmsMenuItem(), drawHelmsMenu()", function()
        it("adds and removes menu items", function()
            local player = eePlayerMock()
            Player:withMenu(player)

            player:addHelmsMenuItem("submenu", mockSubmenu("Submenu 1"))
            assert.is_true(player:hasButton("helms", "Submenu 1"))
            player:addHelmsMenuItem(mockSubmenu("Submenu 2"))
            assert.is_true(player:hasButton("helms", "Submenu 2"))

            player:addHelmsMenuItem("label", mockMenuLabel("Label 1"))
            assert.is_true(player:hasButton("helms", "Label 1"))
            player:addHelmsMenuItem(mockMenuLabel("Label 2"))
            assert.is_true(player:hasButton("helms", "Label 2"))

            player:addHelmsMenuItem("sideeffects", mockMenuItemWithSideEffects("Effect 1"))
            assert.is_true(player:hasButton("helms", "Effect 1"))
            player:addHelmsMenuItem(mockMenuItemWithSideEffects("Effect 2"))
            assert.is_true(player:hasButton("helms", "Effect 2"))

            player:removeHelmsMenuItem("submenu")
            assert.is_false(player:hasButton("helms", "Submenu 1"))

            player:removeHelmsMenuItem("label")
            assert.is_false(player:hasButton("helms", "Label 1"))

            player:removeHelmsMenuItem("sideeffects")
            assert.is_false(player:hasButton("helms", "Effect 1"))

            -- you usually do not need to call that, but lets see if it throws an error
            player:drawHelmsMenu()
        end)
    end)
    describe("addMenuItem(), removeMenuItem(), drawMenu()", function()
        it("adds and removes menu items", function()
            local player = eePlayerMock()
            Player:withMenu(player)

            player:addMenuItem("engineering", "submenu", mockSubmenu("Submenu 1"))
            assert.is_true(player:hasButton("engineering", "Submenu 1"))
            player:addMenuItem("engineering", mockSubmenu("Submenu 2"))
            assert.is_true(player:hasButton("engineering", "Submenu 2"))
            
            player:addMenuItem("engineering", "label", mockMenuLabel("Label 1"))
            assert.is_true(player:hasButton("engineering", "Label 1"))
            player:addMenuItem("engineering", mockMenuLabel("Label 2"))
            assert.is_true(player:hasButton("engineering", "Label 2"))
            
            player:addMenuItem("engineering", "sideeffects", mockMenuItemWithSideEffects("Effect 1"))
            assert.is_true(player:hasButton("engineering", "Effect 1"))
            player:addMenuItem("engineering", mockMenuItemWithSideEffects("Effect 2"))
            assert.is_true(player:hasButton("engineering", "Effect 2"))

            player:removeMenuItem("engineering", "submenu")
            assert.is_false(player:hasButton("engineering", "Submenu 1"))
            
            player:removeMenuItem("engineering", "label")
            assert.is_false(player:hasButton("engineering", "Label 1"))

            player:removeMenuItem("engineering", "sideeffects")
            assert.is_false(player:hasButton("engineering", "Effect 1"))

            -- you usually do not need to call that, but lets test in anyways
            player:drawMenu("engineering")
        end)
    end)
    describe("addMenuItem()", function()
        it("fails if an invalid position is given", function()
            local player = eePlayerMock()
            Player:withMenu(player)

            assert.has_error(function()
                player:addMenuItem("invalid", mockSubmenu())
            end)
            assert.has_error(function()
                player:addMenuItem(nil, mockSubmenu())
            end)
            assert.has_error(function()
                player:addMenuItem(42, mockSubmenu())
            end)
        end)
    end)
    describe("removeMenuItem()", function()
        it("fails if an invalid position is given", function()
            local player = eePlayerMock()
            Player:withMenu(player)

            assert.has_error(function()
                player:removeMenuItem("invalid", "id")
            end)
            assert.has_error(function()
                player:removeMenuItem(nil, "id")
            end)
            assert.has_error(function()
                player:removeMenuItem(42, "id")
            end)
        end)
    end)
    describe("drawMenu()", function()
        it("fails if an invalid position is given", function()
            local player = eePlayerMock()
            Player:withMenu(player)

            assert.has_error(function()
                player:drawMenu("invalid")
            end)
            assert.has_error(function()
                player:drawMenu(nil)
            end)
            assert.has_error(function()
                player:drawMenu(42)
            end)
        end)

        it("can draw an arbitrary menu", function()
            -- test setup
            local player = eePlayerMock()
            Player:withMenu(player, {
                backLabel = "Back",
            })

            player:addMenuItem("weapons", mockSubmenu("Original Item 1"))
            player:addMenuItem("weapons", mockMenuLabel("Original Item 2"))
            assert.is_true(player:hasButton("weapons", "Original Item 1"))
            assert.is_true(player:hasButton("weapons", "Original Item 2"))
            assert.is_false(player:hasButton("weapons", "Back"))

            local overrideMenu = Menu:new()
            overrideMenu:addItem(mockMenuLabel("Override Item"))

            player:drawMenu("weapons", overrideMenu)
            assert.is_false(player:hasButton("weapons", "Original Item 1"))
            assert.is_false(player:hasButton("weapons", "Original Item 2"))
            assert.is_true(player:hasButton("weapons", "Override Item"))

            -- there should ALWAYS! be a back button so the player can go back to the main menu
            assert.is_true(player:hasButton("weapons", "Back"))
            player:clickButton("weapons", "Back")

            assert.is_true(player:hasButton("weapons", "Original Item 1"))
            assert.is_true(player:hasButton("weapons", "Original Item 2"))
            assert.is_false(player:hasButton("weapons", "Override Item"))
            assert.is_false(player:hasButton("weapons", "Back"))
        end)
    end)
end)