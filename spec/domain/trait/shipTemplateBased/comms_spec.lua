insulate("ShipTemplateBased:withComms()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local player = PlayerSpaceship()

    it("causes hasComms() to be true", function()
        local station = SpaceStation()

        ShipTemplateBased:withComms(station)
        assert.is_true(ShipTemplateBased:hasComms(station))
    end)
    it("sets a comms script", function()
        local station = SpaceStation()
        local called = false
        station.setCommsScript = function() called = true end

        ShipTemplateBased:withComms(station)
        assert.is_true(called)
    end)
    it("fails if first argument is already a SpaceObject with comms", function()
        local station = SpaceStation()

        ShipTemplateBased:withComms(station)
        assert.has_error(function() ShipTemplateBased:withComms(station) end)
    end)
    it("fails if first parameter is a number", function()
        assert.has_error(function() ShipTemplateBased:withComms(4) end)
    end)
    it("can set a hail text", function()
        local hail = "Hello World"
        local station = SpaceStation()

        ShipTemplateBased:withComms(station, {hailText = hail})
        assert.is_same(hail, station:getComms(player):getWhatNpcSays(station, player))
    end)
    it("fails if the hailText is a number", function()
        local station = SpaceStation()
        assert.has_error(function() ShipTemplateBased:withComms(station, {hailText = 42})end)
    end)
    it("can set comms", function()
        local station = SpaceStation()

        ShipTemplateBased:withComms(station, {comms = { commsScreenReplyMock(), commsScreenReplyMock(), commsScreenReplyMock()}})
        assert.is_same(3, Util.size(station:getComms(player):getHowPlayerCanReact()))
    end)
    it("fails if comms is a number", function()
        local station = SpaceStation()

        assert.has_error(function() ShipTemplateBased:withComms(station, {comms = 42}) end)
    end)
    it("fails if one of the comms is not a comms", function()
        local station = SpaceStation()

        assert.has_error(function() ShipTemplateBased:withComms(station, {comms = { commsScreenReplyMock(), commsScreenReplyMock(), 42}}) end)
    end)
    it("fails if second argument is not a table", function()
        local station = SpaceStation()
        assert.has_error(function() ShipTemplateBased:withComms(station, 42) end)
    end)

    describe(":setHailText()", function()
        local station = SpaceStation()
        ShipTemplateBased:withComms(station)

        it("returns a set string", function()
            local hail = "Hello World"
            station:setHailText(hail)
            assert.is_same(hail, station:getComms(player):getWhatNpcSays(station, player))
        end)
        it("calls a set function and returns nil", function()
            station:setHailText(function() end)
            assert.is_same("", station:getComms(player):getWhatNpcSays(station, player))
        end)
        it("calls a set function and returns a string", function()
            local hail = "Hello World"
            station:setHailText(function(callStation, callPlayer)
                assert.is_same(station, callStation)
                assert.is_same(player, callPlayer)
                return hail
            end)
            assert.is_same(hail, station:getComms(player):getWhatNpcSays(station, player))
        end)
        it("calls a set function and returns nil if the return value is a number", function()
            station:setHailText(function() return 42 end)
            assert.is_same("", station:getComms(player):getWhatNpcSays(station, player))
        end)
        it("return nil if nil was set", function()
            station:setHailText(nil)
            assert.is_same("", station:getComms(player):getWhatNpcSays(station, player))
        end)
    end)

    describe(":addComms()", function()
        it("allows to be called with a reply", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)
            station:addComms(commsScreenReplyMock())

            assert.is_same(1, Util.size(station:getComms(player):getHowPlayerCanReact()))
        end)

        it("fails if no reply is given", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            assert.has_error(function() station:addComms() end)
        end)

        it("fails if reply is a number", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            assert.has_error(function() station:addComms(42) end)
        end)

        it("generates an id if none is set", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)
            local id = station:addComms(commsScreenReplyMock())

            assert.not_nil(id)
            assert.is_true(isString(id))
            assert.not_same("", id)
        end)

        it("uses a given id", function()
            local id = "foobar"
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            assert.is_same(id, station:addComms(commsScreenReplyMock(), id))
        end)

        it("fails if a number is given as id", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            assert.has_error(function() station:addComms(commsScreenReplyMock(), 42) end)
        end)
    end)

    describe(":getComms()", function()
        it("returns all replies from the constructor and addComms()", function()
            local reply1 = commsScreenReplyMock()
            local reply2 = commsScreenReplyMock()
            local reply3 = commsScreenReplyMock()

            local station = SpaceStation()
            ShipTemplateBased:withComms(station, {comms = { reply1 }})
            station:addComms(reply2)
            station:addComms(reply3)

            local comms = station:getComms(player)
            assert.is_true(Comms:isScreen(comms))
            assert.contains_value(reply1, comms:getHowPlayerCanReact())
            assert.contains_value(reply2, comms:getHowPlayerCanReact())
            assert.contains_value(reply3, comms:getHowPlayerCanReact())
        end)
        it("fails if it is called without argument", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            assert.has_error(function() station:getComms() end)
        end)
        it("fails if it is called with a number", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            assert.has_error(function() station:getComms(42) end)
        end)
        it("does not allow to manipulate internal state", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station, {comms = { commsScreenReplyMock() }})
            local comms = station:getComms(player)

            table.insert(comms:getHowPlayerCanReact(), commsScreenReplyMock())

            assert.is_same(1, Util.size(station:getComms(player):getHowPlayerCanReact()))
        end)
    end)

    describe(":removeComms()", function()
        it("allows to remove a comms that has been added before", function()
            local station = SpaceStation()
            local reply = commsScreenReplyMock()
            ShipTemplateBased:withComms(station)
            local id = station:addComms(reply)
            station:addComms(commsScreenReplyMock())
            station:addComms(commsScreenReplyMock())

            station:removeComms(id)
            assert.not_contains_value(reply, station:getComms(player):getHowPlayerCanReact())
        end)
        it("fails silently if an invalid id is given", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            station:removeComms("does not exist")
            assert.is_same({}, station:getComms(player):getHowPlayerCanReact())
        end)
        it("fails if a number is given instead of an id", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            assert.has_error(function() station:removeComms(42) end)
        end)
    end)

    describe(":overrideComms()", function()
        it("allows to permanently override comms", function()
            local station = SpaceStation()

            ShipTemplateBased:withComms(station)
            local screen = commsScreenMock()

            station:overrideComms(screen)
            assert.is_same(screen:getWhatNpcSays(station, player), station:getComms(player):getWhatNpcSays(station, player))
            assert.is_same(screen:getHowPlayerCanReact(), station:getComms(player):getHowPlayerCanReact())
        end)
        it("allows to remove override", function()
            local station = SpaceStation()

            ShipTemplateBased:withComms(station)
            local screen = commsScreenMock()

            station:overrideComms(screen)
            assert.is_same(screen, station:getComms(player))
            station:overrideComms(nil)
            assert.not_same(screen, station:getComms(player))
        end)
        it("allows to override comms once", function()
            local station = SpaceStation()

            ShipTemplateBased:withComms(station)
            local screen = commsScreenMock()

            station:overrideComms(screen, true)
            assert.is_same(screen, station:getComms(player))
            assert.not_same(screen, station:getComms(player))
        end)
        it("fails if first argument is not a screen", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)

            assert.has_error(function() station:overrideComms(42) end)
        end)
        it("fails if second argument is not boolean", function()
            local station = SpaceStation()
            ShipTemplateBased:withComms(station)
            local screen = commsScreenMock()

            assert.has_error(function() station:overrideComms(screen, 42) end)
        end)
    end)
end)