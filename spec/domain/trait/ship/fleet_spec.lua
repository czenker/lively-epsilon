insulate("Station", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local function fleetMock(ships)
        local id = Util.randomUuid()
        local fleet = {
            getId = function() return id end,
            isValid = function() return true end,
            getShips = function() return ships end,
            countShips = function() return Util.size(ships) end,
            getLeader = function() return ships[1] end,
        }

        assert.is_true(Fleet:isFleet(fleet))

        return fleet
    end


    describe(":withFleet()", function()
        it("should create a ship with fleet", function()
            local ship = CpuShip()
            local fleet = fleetMock({ship})
            Ship:withFleet(ship, fleet)

            assert.is_true(Ship:hasFleet(ship))
        end)
        it("fails when no ship is given", function()
            local ship = CpuShip()
            local fleet = fleetMock({ship})

            assert.has_error(function() Ship:withFleet(42, fleet) end)
        end)
        it("fails when no fleet is given", function()
            local ship = CpuShip()

            assert.has_error(function() Ship:withFleet(ship, 42) end)
        end)
        it("fails if ship already has a fleet", function()
            local ship = CpuShip()
            local fleet = fleetMock({ship})
            Ship:withFleet(ship, fleet)

            assert.has_error(function() Ship:withFleet(ship, fleet) end)
        end)
    end)

    describe(":getFleet()", function()
        it("returns the fleet", function()
            local ship = CpuShip()
            local fleet = fleetMock({ship})
            Ship:withFleet(ship, fleet)

            assert.is_same(fleet, ship:getFleet())
        end)
    end)

    describe(":getFleetLeader()", function()
        it("returns the leader of the fleet", function()
            local ship = CpuShip()
            local fleet = fleetMock({ship})
            fleet.getLeader = function(self) return ship end

            Ship:withFleet(ship, fleet)

            assert.is_same(ship, ship:getFleetLeader())
        end)
    end)

    describe(":isFleetLeader()", function()
        it("returns true if ship is the fleet leader", function()
            local ship1 = CpuShip()
            local ship2 = CpuShip()
            local fleet = fleetMock({ship1, ship2})
            fleet.getLeader = function(self) return ship1 end

            Ship:withFleet(ship1, fleet)
            Ship:withFleet(ship2, fleet)

            assert.is_true(ship1:isFleetLeader())
            assert.is_false(ship2:isFleetLeader())
        end)
    end)
end)