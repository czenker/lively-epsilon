insulate("Chatter", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe("newFactory()", function()
        it("should create a valid chat", function()
            local chat = Chatter:newFactory(1, function(one)
                return {
                    {one, "Hello World"}
                }
            end)

            assert.is_true(Chatter:isChatFactory(chat))
            assert.is_same(1, chat:getCardinality())
            assert.is_true(chat:areValidArguments(CpuShip()))
        end)
        it("fails if first parameter is not a positive integer", function()
            assert.has_error(function() Chatter:newFactory(-1, function() end) end)
            assert.has_error(function() Chatter:newFactory(0, function() end) end)
            assert.has_error(function() Chatter:newFactory(nil, function() end) end)
            assert.has_error(function() Chatter:newFactory("string", function() end) end)
            assert.has_error(function() Chatter:newFactory(SpaceStation(), function() end) end)
        end)
        it("fails if second parameter is not a function", function()
            assert.has_error(function() Chatter:newFactory(1, 1) end)
            assert.has_error(function() Chatter:newFactory(1, "string") end)
            assert.has_error(function() Chatter:newFactory(1, nil) end)
            assert.has_error(function() Chatter:newFactory(1, SpaceStation()) end)
        end)
        it("fails if third parameter is not a table", function()
            assert.has_error(function() Chatter:newFactory(1, function() end, 1) end)
            assert.has_error(function() Chatter:newFactory(1, function() end, "string") end)
        end)
        it("fails if config.filters is not a numeric table", function()
            assert.has_error(function() Chatter:newFactory(1, function() end, {
                filters = 1,
            }) end)
            assert.has_error(function() Chatter:newFactory(1, function() end, {
                filters = "string",
            }) end)
            assert.has_error(function() Chatter:newFactory(1, function() end, {
                filters = {foo = "bar"},
            }) end)
        end)
    end)

    describe("Factory", function()

        describe("areValidArguments", function()
            it("always returns true if no filter is set", function()
                local chat = Chatter:newFactory(1, function() end)

                assert.is_true(chat:areValidArguments(SpaceStation()))
                assert.is_true(chat:areValidArguments(CpuShip()))
            end)
            it("returns false if no shipTemplateBased is given", function()
                local chat = Chatter:newFactory(1, function() end)

                assert.is_false(chat:areValidArguments(1))
                assert.is_false(chat:areValidArguments(Asteroid()))
            end)

            it("works with one partner", function()
                local chat = Chatter:newFactory(1, function() end, {
                    filters = {
                        function(one) return isEeStation(one) end
                    }
                })

                assert.is_true(chat:areValidArguments(SpaceStation()))
                assert.is_false(chat:areValidArguments(CpuShip()))
            end)

            it("works with two partners", function()
                local chat = Chatter:newFactory(2, function() end, {
                    filters = {
                        function(one) return isEeStation(one) end,
                        function(two, _) return isEeShip(two) end,
                    }
                })

                assert.is_true(chat:areValidArguments(SpaceStation()))
                assert.is_false(chat:areValidArguments(CpuShip()))

                assert.is_false(chat:areValidArguments(CpuShip(), SpaceStation()))
                assert.is_true(chat:areValidArguments(SpaceStation(), CpuShip()))
            end)

            it("uses filter on all arguments and gives other partners to filter function", function()
                local oneCalled, twoCalled, threeCalled = 0, 0, 0
                local oneArg1
                local twoArg1, twoArg2
                local threeArg1, threeArg2, threeArg3

                local one, two, three = SpaceStation(), CpuShip(), CpuShip()

                local chat = Chatter:newFactory(3, function() end, {
                    filters = {
                        function(one)
                            oneCalled = oneCalled + 1
                            oneArg1 = one
                            return true
                        end,
                        function(two, one)
                            twoCalled = twoCalled + 1
                            twoArg1 = two
                            twoArg2 = one
                            return true
                        end,
                        function(three, two, one)
                            threeCalled = threeCalled + 1
                            threeArg1 = three
                            threeArg2 = two
                            threeArg3 = one
                            return true
                        end,
                    }
                })

                assert.is_true(chat:areValidArguments(one, two, three))
                assert.is_same(1, oneCalled)
                assert.is_same(one, oneArg1)
                assert.is_same(1, twoCalled)
                assert.is_same(two, twoArg1)
                assert.is_same(one, twoArg2)
                assert.is_same(1, threeCalled)
                assert.is_same(three, threeArg1)
                assert.is_same(two, threeArg2)
                assert.is_same(one, threeArg3)
            end)
        end)

        describe("createChat", function()
            it("gives all arguments to the factory", function()
                local factoryCalled = 0
                local factoryArg1, factoryArg2
                local ship1, ship2 = CpuShip(), CpuShip()

                local chat = Chatter:newFactory(1, function(arg1, arg2)
                    factoryCalled = factoryCalled + 1
                    factoryArg1, factoryArg2 = arg1, arg2

                    return {
                        {arg1, "Hello World"},
                        {arg2, "Foobar"},
                    }
                end)

                local result = chat:createChat(ship1, ship2)
                assert.is_same(1, factoryCalled)
                assert.is_same(ship1, factoryArg1)
                assert.is_same(ship2, factoryArg2)

                assert.is_same("table", type(result))
            end)
        end)
    end)
end)