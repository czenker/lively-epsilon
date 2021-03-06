insulate("Player:withMenu()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("creates a valid menu", function()
        local player = PlayerSpaceship()
        Player:withMenu(player)

        assert.is_true(Player:hasMenu(player))
    end)

    it("fails if the first argument is not a player", function()
        assert.has_error(function() Player:withMenu(42) end)
    end)

    it("fails if the first argument already has menus", function()
        local player = PlayerSpaceship()
        Player:withMenu(player)

        assert.has_error(function() Player:withMenu(player) end)
    end)

    it("draws submenus", function()
        -- test setup
        local player = PlayerSpaceship()
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
        local player = PlayerSpaceship()
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

    it("lets menus fall back to the 4/3 station and single pilot", function()
        local player = PlayerSpaceship()
        Player:withMenu(player)

        local helmsCalled = 0
        local weaponsCalled = 0
        local relayCalled = 0
        local scienceCalled = 0
        local engineeringCalled = 0
        player:addHelmsMenuItem("helms", Menu:newItem("Helms", function() helmsCalled = helmsCalled + 1 end))
        player:addWeaponsMenuItem("weapons", Menu:newItem("Weapons", function() weaponsCalled = weaponsCalled + 1 end))
        player:addRelayMenuItem("relay", Menu:newItem("Relay", function() relayCalled = relayCalled + 1 end))
        player:addScienceMenuItem("science", Menu:newItem("Science", function() scienceCalled = scienceCalled + 1 end))
        player:addEngineeringMenuItem("engineering", Menu:newItem("Engineering", function() engineeringCalled = engineeringCalled + 1 end))

        assert.is_true(player:hasButton("tactical", "Helms"))
        assert.is_true(player:hasButton("tactical", "Weapons"))
        assert.is_true(player:hasButton("operations", "Relay"))
        assert.is_true(player:hasButton("operations", "Science"))
        assert.is_true(player:hasButton("engineering+", "Engineering"))

        assert.is_true(player:hasButton("single", "Helms"))
        assert.is_true(player:hasButton("single", "Weapons"))
        assert.is_true(player:hasButton("single", "Relay"))
        assert.is_true(player:hasButton("single", "Science"))
        assert.is_true(player:hasButton("single", "Engineering"))
    end)

    it("does not change menus on the 6/5 stations when buttons on the 4/3 stations are clicked", function()
        local player = PlayerSpaceship()
        Player:withMenu(player, {
            backLabel = "Back",
        })

        local submenu = mockSubmenu("Submenu", function(menu)
            menu:addItem(mockMenuLabel("You are in a submenu"))
        end)

        player:addScienceMenuItem(submenu)

        assert.is_true(player:hasButton("science", "Submenu"))
        assert.is_true(player:hasButton("operations", "Submenu"))
        assert.is_false(player:hasButton("science", "Back"))
        assert.is_false(player:hasButton("operations", "Back"))

        player:clickButton("operations", "Submenu")
        assert.is_false(player:hasButton("operations", "Submenu"))
        assert.is_true(player:hasButton("operations", "You are in a submenu"))
        assert.is_true(player:hasButton("operations", "Back"))

        assert.is_true(player:hasButton("science", "Submenu"))
        assert.is_false(player:hasButton("science", "You are in a submenu"))
        assert.is_false(player:hasButton("science", "Back"))

        player:clickButton("science", "Submenu")
        assert.is_false(player:hasButton("science", "Submenu"))
        assert.is_true(player:hasButton("science", "You are in a submenu"))
        assert.is_true(player:hasButton("science", "Back"))

        player:clickButton("operations", "Back")
        assert.is_true(player:hasButton("operations", "Submenu"))
        assert.is_false(player:hasButton("operations", "Back"))

        assert.is_false(player:hasButton("science", "Submenu"))
        assert.is_true(player:hasButton("science", "You are in a submenu"))
        assert.is_true(player:hasButton("science", "Back"))
    end)

    it("only shows a message on the station where the button was clicked", function()
        local player = PlayerSpaceship()
        Player:withMenu(player)

        player:addHelmsMenuItem("button", Menu:newItem("Click Me", function() return "Hey, it's me: your friendly pop up" end))

        player:clickButton("tactical", "Click Me")
        assert.is_same("Hey, it's me: your friendly pop up", player:getCustomMessage("tactical"))
        assert.is_nil(player:getCustomMessage("helms"))

        player:clickButton("helms", "Click Me")
        assert.is_same("Hey, it's me: your friendly pop up", player:getCustomMessage("helms"))
    end)

    describe("addHelmsMenuItem(), removeHelmsMenuItem(), drawHelmsMenu()", function()
        it("adds and removes menu items", function()
            local player = PlayerSpaceship()
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

    it("should not have functions for tactical, operations, engineering+ and single pilot", function()
        local player = PlayerSpaceship()
        Player:withMenu(player)

        assert.is_nil(player.addTacticalMenuItem)
        assert.is_nil(player.addOperationsMenuItem)
        assert.is_nil(player.addSingleMenuItem)
        assert.is_nil(player.removeTacticalMenuItem)
        assert.is_nil(player.removeOperationsMenuItem)
        assert.is_nil(player.removeSingleMenuItem)
        assert.is_nil(player.drawTacticalMenu)
        assert.is_nil(player.drawOperationsMenu)
        assert.is_nil(player.drawSingleMenu)

        assert.has_error(function()
            player:addMenuItem("operations", Menu:newItem("Boom", "This should not work"))
        end)
        assert.has_error(function()
            player:addMenuItem("tactical", Menu:newItem("Boom", "This should not work"))
        end)
        assert.has_error(function()
            player:addMenuItem("engineering+", Menu:newItem("Boom", "This should not work"))
        end)
        assert.has_error(function()
            player:addMenuItem("single", Menu:newItem("Boom", "This should not work"))
        end)
    end)

    describe("addMenuItem(), removeMenuItem(), drawMenu()", function()
        it("adds and removes menu items", function()
            local player = PlayerSpaceship()
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

        it("does not redraw the menu if some submenu is currently opened", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {backLabel = "Back"})

            local menu = Menu:new()
            menu:addItem("dummy", Menu:newItem("You are in the submenu"))

            player:addMenuItem("engineering", "submenu", Menu:newItem("Submenu", menu))
            player:clickButton("engineering", "Submenu")

            assert.is_true(player:hasButton("engineering", "You are in the submenu"))
            player:addMenuItem("engineering", "dummy", mockMenuLabel("Main Menu"))

            -- assert you are not thrown back to the main menu
            assert.is_true(player:hasButton("engineering", "You are in the submenu"))
            player:clickButton("engineering", "Back")
            assert.is_true(player:hasButton("engineering", "Main Menu"))
            player:clickButton("engineering", "Submenu")
            assert.is_true(player:hasButton("engineering", "You are in the submenu"))

            player:removeMenuItem("engineering", "dummy")

            -- assert you are not thrown back to the main menu
            assert.is_true(player:hasButton("engineering", "You are in the submenu"))
            player:clickButton("engineering", "Back")
            assert.is_false(player:hasButton("engineering", "Main Menu"))
        end)
    end)
    describe(":addMenuItem()", function()
        it("fails if an invalid position is given", function()
            local player = PlayerSpaceship()
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
    describe(":removeMenuItem()", function()
        it("fails if an invalid position is given", function()
            local player = PlayerSpaceship()
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
    describe(":drawMenu()", function()
        it("fails if an invalid position is given", function()
            local player = PlayerSpaceship()
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
            local player = PlayerSpaceship()
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

        it("paginates long main menus", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {
                backLabel = "Back",
                labelNext = "Next",
                labelPrevious = "Previous",
                itemsPerPage = 8,
            })
            for i=1,10 do
                player:addMenuItem("helms", mockMenuLabel("Item " .. i, i))
            end
            assert.is_true(player:hasButton("helms", "Item 1"))
            assert.is_true(player:hasButton("helms", "Item 2"))
            assert.is_true(player:hasButton("helms", "Item 3"))
            assert.is_true(player:hasButton("helms", "Item 4"))
            assert.is_true(player:hasButton("helms", "Item 5"))
            assert.is_true(player:hasButton("helms", "Item 6"))
            assert.is_true(player:hasButton("helms", "Item 7"))
            assert.is_false(player:hasButton("helms", "Item 8"))
            assert.is_true(player:hasButton("helms", "Next"))
            assert.is_false(player:hasButton("helms", "Previous"))

            player:clickButton("helms", "Next")
            assert.is_false(player:hasButton("helms", "Item 7"))
            assert.is_true(player:hasButton("helms", "Item 8"))
            assert.is_true(player:hasButton("helms", "Item 9"))
            assert.is_true(player:hasButton("helms", "Item 10"))
            assert.is_false(player:hasButton("helms", "Next"))
            assert.is_true(player:hasButton("helms", "Previous"))

            player:clickButton("helms", "Previous")
            assert.is_true(player:hasButton("helms", "Item 1"))
            assert.is_true(player:hasButton("helms", "Item 2"))
            assert.is_true(player:hasButton("helms", "Item 3"))
            assert.is_true(player:hasButton("helms", "Item 4"))
            assert.is_true(player:hasButton("helms", "Item 5"))
            assert.is_true(player:hasButton("helms", "Item 6"))
            assert.is_true(player:hasButton("helms", "Item 7"))
            assert.is_false(player:hasButton("helms", "Item 8"))
        end)
        it("draws a main menu on one page if it fits", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {
                backLabel = "Back",
                labelNext = "Next",
                labelPrevious = "Previous",
                itemsPerPage = 8,
            })
            for i=1,8 do
                player:addMenuItem("helms", mockMenuLabel("Item " .. i, i))
            end
            assert.is_true(player:hasButton("helms", "Item 1"))
            assert.is_true(player:hasButton("helms", "Item 2"))
            assert.is_true(player:hasButton("helms", "Item 3"))
            assert.is_true(player:hasButton("helms", "Item 4"))
            assert.is_true(player:hasButton("helms", "Item 5"))
            assert.is_true(player:hasButton("helms", "Item 6"))
            assert.is_true(player:hasButton("helms", "Item 7"))
            assert.is_true(player:hasButton("helms", "Item 8"))
            assert.is_false(player:hasButton("helms", "Next"))
            assert.is_false(player:hasButton("helms", "Previous"))
        end)
        it("draws the last page of the main menu on one page if it fits", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {
                backLabel = "Back",
                labelNext = "Next",
                labelPrevious = "Previous",
                itemsPerPage = 6,
            })
            for i=1,14 do
                player:addMenuItem("helms", mockMenuLabel("Item " .. i, i))
            end
            assert.is_true(player:hasButton("helms", "Item 1"))
            assert.is_true(player:hasButton("helms", "Item 2"))
            assert.is_true(player:hasButton("helms", "Item 3"))
            assert.is_true(player:hasButton("helms", "Item 4"))
            assert.is_true(player:hasButton("helms", "Item 5"))
            assert.is_false(player:hasButton("helms", "Item 6"))
            assert.is_true(player:hasButton("helms", "Next"))
            assert.is_false(player:hasButton("helms", "Previous"))

            player:clickButton("helms", "Next")
            assert.is_false(player:hasButton("helms", "Item 5"))
            assert.is_true(player:hasButton("helms", "Item 6"))
            assert.is_true(player:hasButton("helms", "Item 7"))
            assert.is_true(player:hasButton("helms", "Item 8"))
            assert.is_true(player:hasButton("helms", "Item 9"))
            assert.is_false(player:hasButton("helms", "Item 10"))
            assert.is_true(player:hasButton("helms", "Next"))
            assert.is_true(player:hasButton("helms", "Previous"))

            player:clickButton("helms", "Next")
            assert.is_false(player:hasButton("helms", "Item 9"))
            assert.is_true(player:hasButton("helms", "Item 10"))
            assert.is_true(player:hasButton("helms", "Item 11"))
            assert.is_true(player:hasButton("helms", "Item 12"))
            assert.is_true(player:hasButton("helms", "Item 13"))
            assert.is_true(player:hasButton("helms", "Item 14"))
            assert.is_false(player:hasButton("helms", "Next"))
            assert.is_true(player:hasButton("helms", "Previous"))
        end)
        it("compensates for the back button on submenus", function()
            local player = PlayerSpaceship()
            Player:withMenu(player, {
                backLabel = "Back",
                labelNext = "Next",
                labelPrevious = "Previous",
                itemsPerPage = 6,
            })

            local menu = Menu:new()
            player:addMenuItem("helms", Menu:newItem("Click Me", menu))

            for i=1,11 do
                menu:addItem(mockMenuLabel("Item " .. i, i))
            end

            player:clickButton("helms", "Click Me")

            assert.is_true(player:hasButton("helms", "Item 1"))
            assert.is_true(player:hasButton("helms", "Item 2"))
            assert.is_true(player:hasButton("helms", "Item 3"))
            assert.is_true(player:hasButton("helms", "Item 4"))
            assert.is_false(player:hasButton("helms", "Item 5"))
            assert.is_true(player:hasButton("helms", "Back"))
            assert.is_true(player:hasButton("helms", "Next"))
            assert.is_false(player:hasButton("helms", "Previous"))

            player:clickButton("helms", "Next")
            assert.is_false(player:hasButton("helms", "Item 4"))
            assert.is_true(player:hasButton("helms", "Item 5"))
            assert.is_true(player:hasButton("helms", "Item 6"))
            assert.is_true(player:hasButton("helms", "Item 7"))
            assert.is_false(player:hasButton("helms", "Item 8"))
            assert.is_true(player:hasButton("helms", "Back"))
            assert.is_true(player:hasButton("helms", "Next"))
            assert.is_true(player:hasButton("helms", "Previous"))

            player:clickButton("helms", "Next")
            assert.is_false(player:hasButton("helms", "Item 7"))
            assert.is_true(player:hasButton("helms", "Item 8"))
            assert.is_true(player:hasButton("helms", "Item 9"))
            assert.is_true(player:hasButton("helms", "Item 10"))
            assert.is_true(player:hasButton("helms", "Item 11"))
            assert.is_true(player:hasButton("helms", "Back"))
            assert.is_false(player:hasButton("helms", "Next"))
            assert.is_true(player:hasButton("helms", "Previous"))
        end)
    end)
end)