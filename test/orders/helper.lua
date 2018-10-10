local function buildArgs(customArgs, config)
    local args = {Order}
    for _,v in pairs(customArgs) do table.insert(args, v) end
    table.insert(args, config)

    return table.unpack(args)
end

function testHappyShipCase(constructor, confFunc, it, assert)
    it("does work in a happy scenario with ship", function()
        local conf = confFunc()
        local ship = eeCpuShipMock()
        Ship:withOrderQueue(ship)

        local startCalled, endCalled = 0, 0
        local startArg1, startArg2
        local endArg1, endArg2

        local order = constructor(buildArgs(conf.args, {
            onExecution = function(arg1, arg2)
                startCalled = startCalled + 1
                startArg1, startArg2 = arg1, arg2
            end,
            onCompletion = function(arg1, arg2)
                endCalled = endCalled + 1
                endArg1, endArg2 = arg1, arg2
            end,
        }))

        conf.setUp(ship)
        ship:addOrder(order)

        if conf.assertOrder then assert.is_same(conf.assertOrder, ship:getOrder()) end
        if conf.assertOrderTarget then assert.is_same(conf.assertOrderTarget, ship:getOrderTarget()) end
        if conf.assertOrderTargetLocation then assert.is_same(conf.assertOrderTargetLocation, {ship:getOrderTargetLocation()}) end
        assert.is_same(1, startCalled)
        assert.is_same(0, endCalled)
        assert.is_same(order, startArg1)
        assert.is_same(ship, startArg2)

        Cron.tick(1)
        if conf.assertOrder then assert.is_same(conf.assertOrder, ship:getOrder()) end
        if conf.assertOrderTarget then assert.is_same(conf.assertOrderTarget, ship:getOrderTarget()) end
        if conf.assertOrderTargetLocation then assert.is_same(conf.assertOrderTargetLocation, {ship:getOrderTargetLocation()}) end

        conf.complete(ship)

        Cron.tick(1)
        assert.is_same(1, startCalled)
        assert.is_same(1, endCalled)
        assert.is_same(order, endArg1)
        assert.is_same(ship, endArg2)
    end)
    it("calls the onAbort callback for ships", function()
        local conf = confFunc()
        local ship = eeCpuShipMock()
        Ship:withOrderQueue(ship)

        local abortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil

        local order = constructor(buildArgs(conf.args, {
            onAbort = function(arg1, arg2, arg3)
                abortCalled = abortCalled + 1
                abortArg1, abortArg2, abortArg3 = arg1, arg2, arg3
            end,
        }))

        conf.setUp(ship)
        ship:addOrder(order)

        Cron.tick(1)
        assert.is_same(0, abortCalled)

        ship:abortCurrentOrder()
        assert.is_same(1, abortCalled)
        assert.is_same(order, abortArg1)
        assert.is_same("user", abortArg2)
        assert.is_same(ship, abortArg3)
    end)
end
function testHappyFleetCase(constructor, confFunc, it, assert)
    it("does work in a happy scenario with fleet", function()
        local conf = confFunc()
        local ship1, ship2, ship3 = eeCpuShipMock(), eeCpuShipMock(), eeCpuShipMock()
        local fleet = Fleet:new({ship1, ship2, ship3})
        Fleet:withOrderQueue(fleet)

        local startCalled, endCalled = 0, 0
        local startArg1, startArg2
        local endArg1, endArg2

        local order = constructor(buildArgs(conf.args, {
            onExecution = function(arg1, arg2)
                startCalled = startCalled + 1
                startArg1, startArg2 = arg1, arg2
            end,
            onCompletion = function(arg1, arg2)
                endCalled = endCalled + 1
                endArg1, endArg2 = arg1, arg2
            end,
        }))

        conf.setUp(fleet)
        fleet:addOrder(order)

        if conf.assertOrder then assert.is_same(conf.assertOrder, fleet:getLeader():getOrder()) end
        if conf.assertOrderTarget then assert.is_same(conf.assertOrderTarget, fleet:getLeader():getOrderTarget()) end
        if conf.assertOrderTargetLocation then assert.is_same(conf.assertOrderTargetLocation, {fleet:getLeader():getOrderTargetLocation()}) end
        assert.is_same(1, startCalled)
        assert.is_same(0, endCalled)
        assert.is_same(order, startArg1)
        assert.is_same(fleet, startArg2)

        Cron.tick(1)
        if conf.assertOrder then assert.is_same(conf.assertOrder, fleet:getLeader():getOrder()) end
        if conf.assertOrderTarget then assert.is_same(conf.assertOrderTarget, fleet:getLeader():getOrderTarget()) end
        if conf.assertOrderTargetLocation then assert.is_same(conf.assertOrderTargetLocation, {fleet:getLeader():getOrderTargetLocation()}) end

        conf.complete(fleet)

        Cron.tick(1)
        assert.is_same(1, startCalled)
        assert.is_same(1, endCalled)
        assert.is_same(order, endArg1)
        assert.is_same(fleet, endArg2)
    end)
    it("carries out orders even after fleet leader died", function()
        local conf = confFunc()
        local ship1, ship2, ship3 = eeCpuShipMock(), eeCpuShipMock(), eeCpuShipMock()
        local fleet = Fleet:new({ship1, ship2, ship3})
        Fleet:withOrderQueue(fleet)
        local order = constructor(buildArgs(conf.args, {}))

        conf.setUp(fleet)
        fleet:addOrder(order)

        if conf.assertOrder then assert.is_same(conf.assertOrder, fleet:getLeader():getOrder()) end
        if conf.assertOrderTarget then assert.is_same(conf.assertOrderTarget, fleet:getLeader():getOrderTarget()) end
        if conf.assertOrderTargetLocation then assert.is_same(conf.assertOrderTargetLocation, {fleet:getLeader():getOrderTargetLocation()}) end

        Cron.tick(1)
        fleet:getLeader():destroy()
        Cron.tick(1)

        if conf.assertOrder then assert.is_same(conf.assertOrder, fleet:getLeader():getOrder()) end
        if conf.assertOrderTarget then assert.is_same(conf.assertOrderTarget, fleet:getLeader():getOrderTarget()) end
        if conf.assertOrderTargetLocation then assert.is_same(conf.assertOrderTargetLocation, {fleet:getLeader():getOrderTargetLocation()}) end
    end)
    it("calls the onAbort callback for fleets", function()
        local conf = confFunc()
        local ship1, ship2, ship3 = eeCpuShipMock(), eeCpuShipMock(), eeCpuShipMock()
        local fleet = Fleet:new({ship1, ship2, ship3})
        Fleet:withOrderQueue(fleet)

        local abortCalled, abortArg1, abortArg2, abortArg3 = 0, nil, nil, nil

        local order = constructor(buildArgs(conf.args, {
            onAbort = function(arg1, arg2, arg3)
                abortCalled = abortCalled + 1
                abortArg1, abortArg2, abortArg3 = arg1, arg2, arg3
            end,
        }))

        conf.setUp(fleet)
        fleet:addOrder(order)

        Cron.tick(1)
        assert.is_same(0, abortCalled)

        fleet:abortCurrentOrder()
        assert.is_same(1, abortCalled)
        assert.is_same(order, abortArg1)
        assert.is_same("user", abortArg2)
        assert.is_same(fleet, abortArg3)
    end)
end

function testSignature(constructor, arguments, it, assert)
    it("creates a valid order", function()
        local order = constructor(buildArgs(arguments, {}))

        assert.is_true(Order:isOrder(order))
    end)
    it("fails if config is not a table", function()
        local ship = eeCpuShipMock()
        Ship:withOrderQueue(ship)

        assert.has_error(function()
            constructor(buildArgs(arguments, 42))
        end)
        assert.has_error(function()
            constructor(buildArgs(arguments, "foobar"))
        end)
    end)
    it("fails if onExecution is not a callback", function()
        local ship = eeCpuShipMock()
        Ship:withOrderQueue(ship)

        assert.has_error(function()
            constructor(buildArgs(arguments, {
                onExecution = 42,
            }))
        end)
        assert.has_error(function()
            constructor(buildArgs(arguments, {
                onExecution = "foo",
            }))
        end)
    end)
    it("fails if onCompletion is not a callback", function()
        local ship = eeCpuShipMock()
        Ship:withOrderQueue(ship)

        assert.has_error(function()
            constructor(buildArgs(arguments, {
                onCompletion = 42,
            }))
        end)
        assert.has_error(function()
            constructor(buildArgs(arguments, {
                onCompletion = "foo",
            }))
        end)
    end)
    it("fails if onAbort is not a callback", function()
        local ship = eeCpuShipMock()
        Ship:withOrderQueue(ship)

        assert.has_error(function()
            constructor(buildArgs(arguments, {
                onAbort = 42,
            }))
        end)
        assert.has_error(function()
            constructor(buildArgs(arguments, {
                onAbort = "foo",
            }))
        end)
    end)
    it("allows to set delayAfter", function()
        local order = constructor(buildArgs(arguments, {
            delayAfter = 42,
        }))

        assert.is_same(42, order:getDelayAfter())
    end)
    it("fails if delayAfter is not a positive number", function()
        local ship = eeCpuShipMock()
        Ship:withOrderQueue(ship)

        assert.has_error(function()
            constructor(buildArgs(arguments, {
                delayAfter = "foo",
            }))
        end)
        assert.has_error(function()
            constructor(buildArgs(arguments, {
                delayAfter = -42,
            }))
        end)
    end)
end
