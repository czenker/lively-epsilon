insulate("documentation on Fleet", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        local ship1, ship2, ship3 = CpuShip(), CpuShip(), CpuShip()
        local enemy = SpaceStation()

        -- tag::basic[]
        local fleet = Fleet:new({ship1, ship2, ship3})

        fleet:orderFlyTowards(1000, 0)
        ship2:orderAttack(enemy) -- wingman will attack the enemy
        ship2:orderIdle() -- wingman will fly back into formation

        if fleet:isValid() then
            fleet:getLeader():destroy()
            -- ship2 will take over the lead and will fly to the next waypoint
        end
        -- end::basic[]
    end)
end)