insulate("Fleet", function()
    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"
    describe("new()", function()
        it("creates a valid fleet", function()
            local fleet = Fleet:new({eeCpuShipMock(), eeCpuShipMock()})

            assert.is_true(Fleet:isFleet(fleet))
        end)
        it("gives all ships the fleet trait", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            Fleet:new({ship1, ship2})

            assert.is_true(Ship:hasFleet(ship1))
            assert.is_true(Ship:hasFleet(ship2))
        end)
        it("does not allow to add ships that are already in a fleet", function()
            local ship = eeCpuShipMock()
            Fleet:new({ship})

            assert.has_error(function() Fleet:new({ship}) end)
        end)
        it("fails if a station is given", function()
            assert.has_error(function() Fleet:new({eeCpuShipMock(), eeStationMock()}) end)
        end)

        it("allows to give config", function()
            local ship = eeCpuShipMock()
            local fleet = Fleet:new({ship}, {id = "foobar"})

            assert.is_true(Fleet:isFleet(fleet))
        end)

        it("fails if the config is not a table", function()
            local ship = eeCpuShipMock()
            assert.has_error(function() Fleet:new({ship}, "This breaks") end)
        end)

        it("fails if id is not a string", function()
            local ship = eeCpuShipMock()
            assert.has_error(function() Fleet:new({ship}, {id = 42}) end)
        end)
    end)

    describe("getId()", function()
        it("returns the given id", function()
            local ship = eeCpuShipMock()
            local fleet = Fleet:new({ship}, {id = "foobar"})

            assert.is_same("foobar", fleet:getId())
        end)

        it("generates an id if none is given", function()
            local ship = eeCpuShipMock()
            local fleet = Fleet:new({ship})

            assert.is_true(isString(fleet:getId()))
            assert.is_not_same("", fleet:getId())
        end)
    end)

    describe("isValid()", function()
        it("it returns true as long as there are valid ships", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()

            local fleet = Fleet:new({ship1, ship2, ship3})

            assert.is_true(fleet:isValid())
            ship1:destroy()
            assert.is_true(fleet:isValid())
            ship2:destroy()
            assert.is_true(fleet:isValid())
            ship3:destroy()
            assert.is_false(fleet:isValid())
        end)
    end)

    describe("getShips()", function()
        it("returns all valid ships", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()

            local fleet = Fleet:new({ship1, ship2, ship3})

            assert.contains_value(ship1, fleet:getShips())
            assert.contains_value(ship2, fleet:getShips())
            assert.contains_value(ship3, fleet:getShips())

            ship1:destroy()
            assert.not_contains_value(ship1, fleet:getShips())
            assert.contains_value(ship2, fleet:getShips())
            assert.contains_value(ship3, fleet:getShips())

            ship2:destroy()
            assert.not_contains_value(ship1, fleet:getShips())
            assert.not_contains_value(ship2, fleet:getShips())
            assert.contains_value(ship3, fleet:getShips())

            ship3:destroy()
            assert.is_same({}, fleet:getShips())
        end)

        it("does not allow to manipulate the result", function()
            local ship = eeCpuShipMock()
            local fleet = Fleet:new({ship})

            local ships = fleet:getShips()
            table.insert(ships, eeCpuShipMock())

            assert.is_same({ship}, fleet:getShips())
        end)
    end)

    describe("countShips()", function()
        it("counts all valid ships", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()

            local fleet = Fleet:new({ship1, ship2, ship3})

            assert.is_same(3, fleet:countShips())

            ship1:destroy()
            assert.is_same(2, fleet:countShips())
            ship3:destroy()
            assert.is_same(1, fleet:countShips())
            ship2:destroy()
            assert.is_same(0, fleet:countShips())
        end)
    end)

    describe("getLeader()", function()
        it("returns the highest ranking valid ship", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()

            local fleet = Fleet:new({ship1, ship2, ship3})

            assert.is_same(ship1, fleet:getLeader())

            ship1:destroy()
            assert.is_same(ship2, fleet:getLeader())
        end)
    end)

    describe("orders", function()
        it("orders all ships to fly in formation", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()

            Fleet:new({ship1, ship2, ship3})

            assert.is_same("Fly in formation", ship2:getOrder())
            assert.is_same("Fly in formation", ship3:getOrder())
        end)
        it("issues orders to fleet leader", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()

            local fleet = Fleet:new({ship1, ship2, ship3})

            fleet:orderRoaming()

            assert.is_same("Roaming", ship1:getOrder())
            assert.is_same("Fly in formation", ship2:getOrder())
            assert.is_same("Fly in formation", ship3:getOrder())
        end)
        it("issues complex orders to fleet leader", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()
            local station = eeStationMock()

            local fleet = Fleet:new({ship1, ship2, ship3})

            fleet:orderDefendTarget(station)

            assert.is_same("Defend Target", ship1:getOrder())
            assert.is_same(station, ship1:getOrderTarget())
            assert.is_same("Fly in formation", ship2:getOrder())
            assert.is_same("Fly in formation", ship3:getOrder())
        end)
        it("fails silently when fleet is invalid", function()
            local ship1 = eeCpuShipMock()

            local fleet = Fleet:new({ship1})

            ship1:destroy()

            fleet:orderRoaming()
        end)
        it("transfers the order if the leader is killed", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()

            local fleet = Fleet:new({ship1, ship2, ship3})

            fleet:orderRoaming()
            ship1:destroy()

            Cron.tick(1)

            assert.is_same("Roaming", ship2:getOrder())
            assert.is_same("Fly in formation", ship3:getOrder())
        end)
    end)

    describe("formation", function()
        it("lets them fly in a nuke-friendly formation", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()
            local ship4 = eeCpuShipMock()
            local ship5 = eeCpuShipMock()

            Fleet:new({ship1, ship2, ship3, ship4, ship5})

            assert.is_same("Fly in formation", ship2:getOrder())
            assert.is_same(-700, ship2:getOrderTargetLocationY())
            assert.is_same(0, ship2:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship3:getOrder())
            assert.is_same(700, ship3:getOrderTargetLocationY())
            assert.is_same(0, ship3:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship4:getOrder())
            assert.is_same(-1400, ship4:getOrderTargetLocationY())
            assert.is_same(0, ship4:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship5:getOrder())
            assert.is_same(1400, ship5:getOrderTargetLocationY())
            assert.is_same(0, ship5:getOrderTargetLocationX())
        end)
        it("fills gaps when a wingman is killed", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()
            local ship4 = eeCpuShipMock()
            local ship5 = eeCpuShipMock()

            Fleet:new({ship1, ship2, ship3, ship4, ship5})

            ship3:destroy()

            Cron.tick(1)

            assert.is_same("Fly in formation", ship2:getOrder())
            assert.is_same(-700, ship2:getOrderTargetLocationY())
            assert.is_same(0, ship2:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship4:getOrder())
            assert.is_same(-1400, ship4:getOrderTargetLocationY())
            assert.is_same(0, ship4:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship5:getOrder())
            assert.is_same(700, ship5:getOrderTargetLocationY())
            assert.is_same(0, ship5:getOrderTargetLocationX())
        end)
        it("fills gaps when the leader is killed and the highest ranking ship is left", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()
            local ship4 = eeCpuShipMock()
            local ship5 = eeCpuShipMock()

            Fleet:new({ship1, ship2, ship3, ship4, ship5})

            ship1:destroy()

            Cron.tick(1)

            assert.is_same("Fly in formation", ship3:getOrder())
            assert.is_same(700, ship3:getOrderTargetLocationY())
            assert.is_same(0, ship3:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship4:getOrder())
            assert.is_same(-700, ship4:getOrderTargetLocationY())
            assert.is_same(0, ship4:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship5:getOrder())
            assert.is_same(1400, ship5:getOrderTargetLocationY())
            assert.is_same(0, ship5:getOrderTargetLocationX())
        end)
        it("fills gaps when the leader is killed and the highest ranking ship is right", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()
            local ship4 = eeCpuShipMock()
            local ship5 = eeCpuShipMock()

            Fleet:new({ship1, ship2, ship3, ship4, ship5})

            ship2:destroy()
            ship1:destroy()

            Cron.tick(1)

            assert.is_same("Fly in formation", ship4:getOrder())
            assert.is_same(-700, ship4:getOrderTargetLocationY())
            assert.is_same(0, ship4:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship5:getOrder())
            assert.is_same(700, ship5:getOrderTargetLocationY())
            assert.is_same(0, ship5:getOrderTargetLocationX())
        end)
    end)

    describe("GM interaction", function()
        it("GM can issue an order to a wingman that is not changed if the leader is killed", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()
            local ship4 = eeCpuShipMock()
            local ship5 = eeCpuShipMock()

            Fleet:new({ship1, ship2, ship3, ship4, ship5})

            ship5:orderDefendLocation(42, 4200)

            Cron.tick(1)

            assert.is_same("Defend Location", ship5:getOrder())
            ship1:destroy()

            assert.is_same("Defend Location", ship5:getOrder())
        end)
        it("GM can reintegrate a wingman by setting order to Idle or Roaming", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()
            local ship4 = eeCpuShipMock()
            local ship5 = eeCpuShipMock()

            Fleet:new({ship1, ship2, ship3, ship4, ship5})

            ship4:orderDefendLocation(42, 4200)
            ship5:orderDefendLocation(42, 4200)

            Cron.tick(1)

            ship4:orderIdle()
            ship5:orderRoaming()

            Cron.tick(1)

            assert.is_same("Fly in formation", ship4:getOrder())
            assert.is_same(-1400, ship4:getOrderTargetLocationY())
            assert.is_same(0, ship4:getOrderTargetLocationX())
            assert.is_same("Fly in formation", ship5:getOrder())
            assert.is_same(1400, ship5:getOrderTargetLocationY())
            assert.is_same(0, ship5:getOrderTargetLocationX())
        end)
        it("GM can issue new orders to fleet leader and are carried out if fleet leader is killed", function()
            local ship1 = eeCpuShipMock()
            local ship2 = eeCpuShipMock()
            local ship3 = eeCpuShipMock()

            Fleet:new({ship1, ship2, ship3})

            ship1:orderDefendLocation(42, 4200)

            Cron.tick(1)

            ship1:destroy()

            Cron.tick(1)

            assert.is_same("Defend Location", ship2:getOrder())
            assert.is_same(42, ship2:getOrderTargetLocationX())
            assert.is_same(4200, ship2:getOrderTargetLocationY())
            assert.is_same("Fly in formation", ship3:getOrder())
        end)
    end)
end)