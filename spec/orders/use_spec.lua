insulate("Order:use()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.orders.helper"

    local wormHole = WormHole():setPosition(5000, 0):setTargetPosition(10000, 0)

    testSignature(Order.use, {wormHole}, it, assert)
    testHappyShipCase(Order.use, function()
        return {
            args = {wormHole},
            setUp = function(ship)
                ship:setPosition(0, 0)
            end,
            assertOrder = "Fly towards",
            assertOrderTarget = nil,
            assertOrderTargetLocation = {5000, 0},
            complete = function(ship)
                ship:setPosition(10000, 0)
            end,
        }
    end, it, assert)
    testHappyFleetCase(Order.use, function()
        return {
            args = { wormHole },
            setUp = function(fleet)
                for _, ship in pairs(fleet:getShips()) do
                    ship:setPosition(0, 0)
                end
            end,
            assertOrder = "Fly towards",
            assertOrderTarget = nil,
            assertOrderTargetLocation = {5000, 0},
            complete = function(fleet)
                for _, ship in pairs(fleet:getShips()) do ship:setPosition(10000, 0) end
            end,
        }
    end, it, assert)

    it("fails if wormHole is not a WormHole", function()
        assert.has_error(function()
            Order:use(nil)
        end)
        assert.has_error(function()
            Order:use("foo")
        end)
        assert.has_error(function()
            Order:use({})
        end)
        assert.has_error(function()
            Order:use(0)
        end)
    end)
    it("fails if wormHole is not valid", function()
        assert.has_error(function()
            local ship = CpuShip()
            local wormhole = WormHole():destroy()

            ship:addOrder(Order:use(wormhole))
        end)
    end)

    it("fails if wormhole disappears", function()
        local ship = CpuShip()
        local wormhole = WormHole():setPosition(0,0):setTargetPosition(10000, 0)

        Ship:withOrderQueue(ship)

        local onAbortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil
        local order = Order:use(wormhole, {
            onAbort = function(arg1, arg2, arg3)
                onAbortCalled = onAbortCalled + 1
                abortArg1 = arg1
                abortArg2 = arg2
                abortArg3 = arg3
            end,
        })
        ship:addOrder(order)

        Cron.tick(1)
        wormhole:destroy()
        Cron.tick(1)

        assert.is_same(1, onAbortCalled)
        assert.is_same(order, abortArg1)
        assert.is_same("invalid_target", abortArg2)
        assert.is_same(ship, abortArg3)
        assert.is_same("Idle", ship:getOrder())
    end)

    it("fleet breaks up in front of the wormhole and calls the config.onBreakUp callback", function()
        local leader = CpuShip()
        local ship1 = CpuShip()
        local ship2 = CpuShip()
        local wormhole = WormHole():setPosition(5000,0):setTargetPosition(99999, 0)

        local fleet = Fleet:new({leader, ship1, ship2})
        Fleet:withOrderQueue(fleet)

        local onBreakUpCalled, breakUpArg1, breakUpArg2 = 0, nil, nil
        local order = Order:use(wormhole, {
            onBreakUp = function(arg1, arg2)
                onBreakUpCalled = onBreakUpCalled + 1
                breakUpArg1 = arg1
                breakUpArg2 = arg2
            end,
        })
        fleet:addOrder(order)
        Cron.tick(1)

        assert.is_same(0, onBreakUpCalled)
        assert.is_same("Fly towards", leader:getOrder())
        assert.is_same("Fly in formation", ship1:getOrder())
        assert.is_same("Fly in formation", ship2:getOrder())

        leader:setPosition(3000, 0)
        Cron.tick(1)
        assert.is_same("Fly towards (ignore all)", leader:getOrder())
        assert.is_same(5000, leader:getOrderTargetLocationX())
        assert.is_same(0, leader:getOrderTargetLocationY())
        assert.is_same("Fly towards (ignore all)", ship1:getOrder())
        assert.is_same(5000, ship1:getOrderTargetLocationX())
        assert.is_same(0, ship1:getOrderTargetLocationY())
        assert.is_same("Fly towards (ignore all)", ship2:getOrder())
        assert.is_same(5000, ship2:getOrderTargetLocationX())
        assert.is_same(0, ship2:getOrderTargetLocationY())
        assert.is_same(1, onBreakUpCalled)
        assert.is_same(order, breakUpArg1)
        assert.is_same(fleet, breakUpArg2)

        Cron.tick(1)
        assert.is_same(1, onBreakUpCalled) -- it is only called once
    end)

    it("fleet waits after jump and regroups", function()
        local leader = CpuShip():setCallSign("leader")
        local ship1 = CpuShip():setCallSign("ship 1")
        local ship2 = CpuShip():setCallSign("ship 2")
        local ship3 = CpuShip():setCallSign("ship 3")
        local wormhole = WormHole():setPosition(5000,0):setTargetPosition(99999, 0)

        local fleet = Fleet:new({leader, ship1, ship2, ship3})
        Fleet:withOrderQueue(fleet)

        local order = Order:use(wormhole)
        fleet:addOrder(order)

        Cron.tick(1)

        assert.is_same("Fly towards", leader:getOrder())
        assert.is_same("Fly in formation", ship1:getOrder())
        assert.is_same("Fly in formation", ship2:getOrder())
        assert.is_same("Fly in formation", ship3:getOrder())

        leader:setPosition(3000, 0)
        Cron.tick(1)
        assert.is_same("Fly towards (ignore all)", leader:getOrder())
        assert.is_same("Fly towards (ignore all)", ship1:getOrder())
        assert.is_same("Fly towards (ignore all)", ship2:getOrder())
        assert.is_same("Fly towards (ignore all)", ship3:getOrder())

        -- wingman jumps first
        ship1:setPosition(99999, 0)
        Cron.tick(1)
        assert.is_same("Fly towards (ignore all)", leader:getOrder())
        assert.is_same("Stand Ground", ship1:getOrder())
        assert.is_same("Fly towards (ignore all)", ship2:getOrder())
        assert.is_same("Fly towards (ignore all)", ship3:getOrder())


        -- leader jumps second
        leader:setPosition(99999, 0)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_same("Stand Ground", leader:getOrder())
        assert.is_same("Fly in formation", ship1:getOrder())
        assert.is_same("Fly towards (ignore all)", ship2:getOrder())
        assert.is_same("Fly towards (ignore all)", ship3:getOrder())

        -- second wingman jumps
        ship2:setPosition(99999, 0)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_same("Stand Ground", leader:getOrder())
        assert.is_same("Fly in formation", ship1:getOrder())
        assert.is_same("Fly in formation", ship2:getOrder())
        assert.is_same("Fly towards (ignore all)", ship3:getOrder())

        ship3:setPosition(99999, 0)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_same("Stand Ground", leader:getOrder())
        assert.is_same("Fly in formation", ship1:getOrder())
        assert.is_same("Fly in formation", ship2:getOrder())
        assert.is_same("Fly in formation", ship3:getOrder())
    end)

    it("fleet leader waits after jump and regroups", function()
        local leader = CpuShip():setCallSign("leader")
        local ship1 = CpuShip():setCallSign("ship 1")
        local ship2 = CpuShip():setCallSign("ship 2")
        local wormhole = WormHole():setPosition(5000,0):setTargetPosition(99999, 0)

        local fleet = Fleet:new({leader, ship1, ship2})
        Fleet:withOrderQueue(fleet)

        local order = Order:use(wormhole)
        fleet:addOrder(order)

        Cron.tick(1)

        assert.is_same("Fly towards", leader:getOrder())
        assert.is_same("Fly in formation", ship1:getOrder())
        assert.is_same("Fly in formation", ship2:getOrder())

        leader:setPosition(3000, 0)
        Cron.tick(1)
        assert.is_same("Fly towards (ignore all)", leader:getOrder())
        assert.is_same("Fly towards (ignore all)", ship1:getOrder())
        assert.is_same("Fly towards (ignore all)", ship2:getOrder())

        -- leader jumps first
        leader:setPosition(99999, 0)
        Cron.tick(1)
        assert.is_same("Stand Ground", leader:getOrder())
        assert.is_same("Fly towards (ignore all)", ship1:getOrder())
        assert.is_same("Fly towards (ignore all)", ship2:getOrder())

        -- wingman jumps second
        ship1:setPosition(99999, 0)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_same("Stand Ground", leader:getOrder())
        assert.is_same("Fly in formation", ship1:getOrder())
        assert.is_same("Fly towards (ignore all)", ship2:getOrder())

        -- second wingman jumps
        ship2:setPosition(99999, 0)
        Cron.tick(1)
        Cron.tick(1)
        assert.is_same("Stand Ground", leader:getOrder())
        assert.is_same("Fly in formation", ship1:getOrder())
        assert.is_same("Fly in formation", ship2:getOrder())
    end)
end)