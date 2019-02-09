insulate("Comms", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local station = SpaceStation()
    local player = PlayerSpaceship()

    describe(":newReply()", function()
        it("can create a reply", function()
            local reply = Comms:newReply("Foobar", function() end)

            assert.is_true(Comms:isReply(reply))
            assert.is_same("Foobar", reply:getWhatPlayerSays(station, player))
        end)
        it("can create a reply with function for name instead of string", function()
            local name = function() return "Foobar" end
            local reply = Comms:newReply(name, function() end)

            assert.is_true(Comms:isReply(reply))
            assert.is_same("Foobar", reply:getWhatPlayerSays(station, player))
        end)
        it("can create a reply with comms screen as return", function()
            local screen = Comms:newScreen("Hello World")
            local reply = Comms:newReply("Foobar", screen)

            assert.is_true(Comms:isReply(reply))
            assert.is_same(screen, reply:getNextScreen(station, player))
        end)
        it("can create a reply condition check", function()
            local condition = function() return true end
            local reply = Comms:newReply("Foobar", nil, condition)

            assert.is_true(Comms:isReply(reply))
            assert.is_true(reply:checkCondition(station, player))
        end)
        it("fails if first argument is a number", function()
            assert.has_error(function() Comms:newReply(42, function() end) end)
        end)
        it("fails if second argument is a number", function()
            assert.has_error(function() Comms:newReply("Foobar", 42) end)
        end)
        it("fails if third argument is a number", function()
            assert.has_error(function() Comms:newReply("Foobar", nil, 42) end)
        end)
    end)

    describe(":newScreen()", function()
        it("can create a comms screen that it validates", function()
            local screen = Comms:newScreen("Hello World", {
                Comms:newReply("One", function() end),
                Comms:newReply("Two", function () end),
            })

            assert.is_true(Comms:isScreen(screen))
            assert.is_same(2, Util.size(screen:getHowPlayerCanReact(station, player)))
        end)

        it("allows to add replies", function()
            local screen = Comms:newScreen("Hello World")
            :addReply(Comms:newReply("One", function() end))
            :addReply(Comms:newReply("Two", function() end))

            assert.is_true(Comms:isScreen(screen))
            assert.is_same(2, Util.size(screen:getHowPlayerCanReact(station, player)))
        end)
    end)


end)