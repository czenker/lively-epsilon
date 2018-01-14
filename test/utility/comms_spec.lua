insulate("Comms", function()
    require "lively_epsilon"

    describe("reply()", function()
        it("can create a reply", function()
            local reply = Comms.reply("Foobar", function() end)

            assert.is_true(Comms.isReply(reply))
            assert.is_same("Foobar", reply:playerSays())
        end)
        it("can create a reply with function instead of string", function()
            local name = function() return "Foobar" end
            local reply = Comms.reply(name, function() end)

            assert.is_true(Comms.isReply(reply))
            assert.is_same("Foobar", reply:playerSays())
        end)
        it("can create a reply condition check", function()
            local condition = function() return true end
            local reply = Comms.reply("Foobar", nil, condition)

            assert.is_true(Comms.isReply(reply))
            assert.is_true(reply:condition())
        end)
        it("fails if first argument is a number", function()
            assert.has_error(function() Comms.reply(42, function() end) end)
        end)
        it("fails if second argument is a number", function()
            assert.has_error(function() Comms.reply("Foobar", 42) end)
        end)
        it("fails if third argument is a number", function()
            assert.has_error(function() Comms.reply("Foobar", nil, 42) end)
        end)
    end)

    describe("screen()", function()
        it("can create a comms screen that it validates", function()
            local screen = Comms.screen("Hello World", {
                Comms.reply("One", function() end),
                Comms.reply("Two", function () end),
            })

            assert.is_true(Comms.isScreen(screen))
            assert.is_same(2, Util.size(screen.howPlayerCanReact))
        end)

        it("allows to add replies", function()
            local screen = Comms.screen("Hello World")
            :withReply(Comms.reply("One", function() end))
            :withReply(Comms.reply("Two", function() end))

            assert.is_true(Comms.isScreen(screen))
            assert.is_same(2, Util.size(screen.howPlayerCanReact))
        end)
    end)


end)