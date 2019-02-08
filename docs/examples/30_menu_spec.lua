insulate("documentation on Menu", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        withUniverse(function()
            -- tag::basic[]
            local player = PlayerSpaceship():setPosition(0, 0)
            Player:withMenu(player)

            CpuShip():setCallSign("Nostromo"):setPosition(1000, 0)
            CpuShip():setCallSign("Planet Express Ship"):setPosition(2000, 0)
            CpuShip():setCallSign("Discovery"):setPosition(3000, 0)

            player:addScienceMenuItem("ships", Menu:newItem("Ships", function()
                local submenu = Menu:new()
                Menu:newItem("Ships")
                for _, ship in pairs(player:getObjectsInRange(30000)) do
                    if ship.typeName == "CpuShip" and ship:isValid() then
                        submenu:addItem(Menu:newItem(ship:getCallSign(), function()
                            return ship:getDescription()
                        end))
                    end
                end
                return submenu
            end))

            -- end::basic[]

            assert.is_true(player:hasButton("science", "Ships"))
            player:clickButton("science", "Ships")
            assert.is_true(player:hasButton("science", "Nostromo"))
            player:clickButton("science", "Nostromo")
        end)
    end)
    it("prio", function()
        -- tag::priority[]
        local player = PlayerSpaceship():setPosition(0, 0)
        Player:withMenu(player)

        player:addHelmsMenuItem("world", Menu:newItem("World"))
        player:addHelmsMenuItem("hello", Menu:newItem("Hello"), -10)
        -- end::priority[]
    end)
    it("backLabel", function()
        -- tag::back[]
        local player = PlayerSpaceship()
        Player:withMenu(player, {
            backLabel = "Back",
        })
        -- end::back[]
    end)
    it("pagination", function()
        -- tag::pagination[]
        local player = PlayerSpaceship()
        Player:withMenu(player)
        for i=1,25 do
            player:addWeaponsMenuItem("option_" .. i, Menu:newItem("Option " .. i, i))
        end
        -- end::pagination[]
        -- tag::pagination-configuration[]
        local player = PlayerSpaceship()
        Player:withMenu(player, {
            labelNext = "Next",
            labelPrevious = "Previous",
            itemsPerPage = 6,
        })
        -- end::pagination-configuration[]
    end)
end)