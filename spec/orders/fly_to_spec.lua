insulate("Order:flyTo()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.orders.helper"

    testSignature(Order.flyTo, {1000, 0}, it, assert)
    testHappyShipCase(Order.flyTo, function()
        return {
            args = {1000, 0},
            setUp = function(ship)
                ship:setPosition(0, 0)
            end,
            assertOrder = "Fly towards",
            assertOrderTarget = nil,
            assertOrderTargetLocation = {1000, 0},
            complete = function(ship)
                ship:setPosition(1000, 0)
            end,
        }
    end, it, assert)
    testHappyFleetCase(Order.flyTo, function()
        return {
            args = {1000, 0},
            setUp = function(fleet)
                for _, ship in pairs(fleet:getShips()) do
                    ship:setPosition(0, 0)
                end
            end,
            assertOrder = "Fly towards",
            assertOrderTarget = nil,
            assertOrderTargetLocation = {1000, 0},
            complete = function(fleet)
                for _, ship in pairs(fleet:getShips()) do ship:setPosition(1000, 0) end
            end,
        }
    end, it, assert)

    it("fails if x or y are not numbers", function()
        assert.has_error(function()
            Order:flyTo(nil, 0)
        end)
        assert.has_error(function()
            Order:flyTo("foo", 0)
        end)
        assert.has_error(function()
            Order:flyTo({}, 0)
        end)
        assert.has_error(function()
            Order:flyTo(0, nil)
        end)
        assert.has_error(function()
            Order:flyTo(0, "foo")
        end)
        assert.has_error(function()
            Order:flyTo(0, {})
        end)
    end)
    describe("config.minDistance", function()
        it("allows to set the distance to trigger for ship", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            ship:setPosition(1000, 0)

            local completed = false
            ship:addOrder(Order:flyTo(0, 0, {
                minDistance = 100,
                onCompletion = function() completed = true end,
            }))

            assert.is_false(completed)

            ship:setPosition(500, 0)
            Cron.tick(1)
            assert.is_false(completed)

            ship:setPosition(101, 0)
            Cron.tick(1)
            assert.is_false(completed)

            ship:setPosition(99, 0)
            Cron.tick(1)
            assert.is_true(completed)
        end)
        it("allows to set the distance to trigger for fleet leader", function()
            local fleet = Fleet:new({
                CpuShip(),
                CpuShip(),
                CpuShip(),
            })
            Fleet:withOrderQueue(fleet)

            fleet:getLeader():setPosition(1000, 0)

            local completed = false
            fleet:addOrder(Order:flyTo(0, 0, {
                minDistance = 100,
                onCompletion = function() completed = true end,
            }))

            assert.is_false(completed)

            fleet:getLeader():setPosition(500, 0)
            Cron.tick(1)
            assert.is_false(completed)

            fleet:getLeader():setPosition(101, 0)
            Cron.tick(1)
            assert.is_false(completed)

            fleet:getLeader():setPosition(99, 0)
            Cron.tick(1)
            assert.is_true(completed)
        end)
        it("fails if it is not a number or negative", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            assert.has_error(function()
                Order:flyTo(0, 0, {
                    minDistance = "foobar",
                })
            end)
            assert.has_error(function()
                Order:flyTo(0, 0, {
                    minDistance = -42,
                })
            end)
        end)
    end)
    describe("config.ignoreEnemies", function()
        it("allows to set the distance to trigger for ship", function()
            local fleet = Fleet:new({
                CpuShip(),
                CpuShip(),
                CpuShip(),
            })
            Fleet:withOrderQueue(fleet)

            fleet:getLeader():setPosition(1000, 0)

            fleet:addOrder(Order:flyTo(0, 0, {
                ignoreEnemies = true,
            }))
            assert.is_same("Fly towards (ignore all)", fleet:getLeader():getOrder())
        end)
        it("allows to set the distance to trigger for fleet", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            ship:setPosition(1000, 0)

            ship:addOrder(Order:flyTo(0, 0, {
                ignoreEnemies = true,
            }))
            assert.is_same("Fly towards (ignore all)", ship:getOrder())
        end)
        it("fails if it is not a boolean", function()
            local ship = CpuShip()
            Ship:withOrderQueue(ship)

            assert.has_error(function()
                Order:flyTo(0, 0, {
                    ignoreEnemies = "foobar",
                })
            end)
            assert.has_error(function()
                Order:flyTo(0, 0, {
                    ignoreEnemies = 42,
                })
            end)
        end)
    end)
end)