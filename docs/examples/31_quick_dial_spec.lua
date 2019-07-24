insulate("documentation on Quick Dial", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        withUniverse(function()
            -- tag::basic[]
            local player = PlayerSpaceship():setPosition(0, 0)
            Player:withMenu(player, { backLabel = "Back" })
            Player:withQuickDial(player, { label = "Quick Dial" })

            local ship = CpuShip():setCallSign("Nostromo"):setPosition(1000, 0)
            local station = SpaceStation():setCallSign("Outpost 42"):setPosition(2000, 0)
            local fleet = Fleet:new({
                CpuShip():setCallSign("Discovery"):setPosition(3000, 0)
            })

            player:addQuickDial(ship)
            player:addQuickDial(station)
            player:addQuickDial(fleet)
            -- end::basic[]

            assert.is_true(player:hasButton("relay", "Quick Dial"))
            player:clickButton("relay", "Quick Dial")
            assert.is_true(player:hasButton("relay", "Nostromo"))
            assert.is_true(player:hasButton("relay", "Outpost 42"))
            assert.is_true(player:hasButton("relay", "Discovery"))
            player:clickButton("relay", "Back")

            -- tag::remove[]
            player:removeQuickDial(ship)
            -- end::remove[]

            player:clickButton("relay", "Quick Dial")
            assert.is_false(player:hasButton("relay", "Nostromo"))
            assert.is_true(player:hasButton("relay", "Outpost 42"))
            assert.is_true(player:hasButton("relay", "Discovery"))
        end)
    end)
end)