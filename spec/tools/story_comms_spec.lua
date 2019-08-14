insulate("Tools:storyComms()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    insulate("valid call", function()
        require "init"
        require "spec.mocks"

        local station = SpaceStation()
        Station:withComms(station)
        local player = PlayerSpaceship()
        local screen = commsScreenMock()

        it("can be created", function()
            finally(function() Tools:endStoryComms() end)

            Tools:storyComms(station, player, screen)
        end)

        it("can be stopped and started again", function()
            finally(function() Tools:endStoryComms() end)

            Tools:endStoryComms()
            Tools:storyComms(station, player, screen)
        end)
    end)

    it("pops up if it is closed before dialog finished", function()
        finally(function() Tools:endStoryComms() end)

        local station = SpaceStation()
        Station:withComms(station)
        local player = PlayerSpaceship()
        local comms = Comms:newScreen("screen one")
        comms:addReply(Comms:newReply("reply one", function()
            local screen2 = Comms:newScreen("screen two")
            screen2:addReply(Comms:newReply("reply two", function()
                Tools:endStoryComms()

                return Comms:newScreen("screen three")
            end))

            return screen2
        end))

        Tools:storyComms(station, player, comms)
        assert.same("screen one", player:getCurrentCommsText())

        -- screen one pops up again if comms is closed
        player:commandCloseTextComm()
        Cron.tick(1)
        assert.same("screen one", player:getCurrentCommsText())

        player:selectComms("reply one")
        assert.same("screen two", player:getCurrentCommsText())
        player:commandCloseTextComm()

        -- conversation starts at screen one again
        player:commandCloseTextComm()
        Cron.tick(1)
        assert.same("screen one", player:getCurrentCommsText())

        player:selectComms("reply one")
        assert.same("screen two", player:getCurrentCommsText())
        player:selectComms("reply two")
        assert.same("screen three", player:getCurrentCommsText())
        player:commandCloseTextComm()
        Cron.tick(1)

        -- comms stays closed
        assert.is_true(player:isCommsInactive())
    end)
    it("ends when player is destroyed", function()
        finally(function() Tools:endStoryComms() end)

        local station = SpaceStation()
        Station:withComms(station)
        local player = PlayerSpaceship()
        local comms = Comms:newScreen("screen one")
        comms:addReply(Comms:newReply("reply one", function()
            Tools:endStoryComms()

            return Comms:newScreen("screen two")
        end))

        Tools:storyComms(station, player, comms)
        assert.same("screen one", player:getCurrentCommsText())

        -- screen one pops up again if comms is closed
        player:commandCloseTextComm()
        player:destroy()
        Cron.tick(1)

        -- comms stays closed
        assert.is_true(player:isCommsInactive())
    end)
    it("ends when station is destroyed", function()
        finally(function() Tools:endStoryComms() end)

        local station = SpaceStation()
        Station:withComms(station)
        local player = PlayerSpaceship()
        local comms = Comms:newScreen("screen one")
        comms:addReply(Comms:newReply("reply one", function()
            Tools:endStoryComms()

            return Comms:newScreen("screen two")
        end))

        Tools:storyComms(station, player, comms)
        assert.same("screen one", player:getCurrentCommsText())

        -- screen one pops up again if comms is closed
        player:commandCloseTextComm()
        station:destroy()
        Cron.tick(1)

        -- comms stays closed
        assert.is_true(player:isCommsInactive())
    end)

    insulate("invalid calls", function()
        require "init"
        require "spec.mocks"

        local station = SpaceStation()
        Station:withComms(station)
        local player = PlayerSpaceship()
        local screen = commsScreenMock()

        it("fails when called without station", function()
            assert.has_error(function() Tools:storyComms(nil, player, screen) end)
        end)
        it("fails when called with station without comms", function()
            assert.has_error(function() Tools:storyComms(SpaceStation(), player, screen) end)
        end)
        it("fails when called without player", function()
            assert.has_error(function() Tools:storyComms(station, nil, screen) end)
        end)
        it("fails when called without screen", function()
            assert.has_error(function() Tools:storyComms(station, player, nil) end)
        end)
        it("fails when an other storyComms() is currently running", function()
            finally(function() Tools:endStoryComms() end)

            Tools:storyComms(station, player, screen)
            assert.has_error(function() Tools:storyComms(station, player, screen) end)
        end)
    end)
end)