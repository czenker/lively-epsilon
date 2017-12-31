insulate("comms", function()
    require "lively_epsilon"

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