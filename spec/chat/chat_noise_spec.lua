
insulate("Chatter", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    describe("newNoise()", function()
        it("creates a valid ChatNoise", function()
            local chatter = mockChatter()
            local noise = Chatter:newNoise(chatter)
            assert.is_true(Chatter:isChatNoise(noise))
        end)
        it("fails when chatter is not a chatter", function()
            local chatter = mockChatter()
            assert.has_error(function()
                Chatter:newNoise(nil)
            end)
            assert.has_error(function()
                Chatter:newNoise("foo")
            end)
            assert.has_error(function()
                Chatter:newNoise(42)
            end)
            assert.has_error(function()
                Chatter:newNoise({})
            end)
        end)
    end)

    describe("Noise", function()
        it("works with a chat with filters", function()
            withUniverse(function(universe)
                local player = PlayerSpaceship():setCallSign("player"):setPosition(0, 0)
                local ship = CpuShip():setCallSign("ship"):setPosition(1000, 0)
                local station = SpaceStation():setCallSign("station"):setPosition(0, 1000)

                universe:add(player, ship, station)

                local chat = Chatter:newFactory(2, function(thisStation, thisShip)
                    return {
                        { thisStation, "Who are you?"},
                        { thisShip, "John Doe"},
                    }
                end, {
                    filters = {
                        function(thing) return isEeStation(thing) end,
                        function(thing) return isEeShip(thing) end,
                    },
                })

                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)
                noise:addChatFactory(chat)

                for _=1,90 do Cron.tick(1) end

                assert.is_same({
                    {station, "Who are you?"},
                    {ship, "John Doe"},
                }, chatter:getLastMessages())
            end)
        end)
        it("works in a complex scenario", function()
            withUniverse(function(universe)
                local player = PlayerSpaceship():setCallSign("player"):setPosition(0, 0)
                local ship = CpuShip():setCallSign("ship"):setPosition(1000, 0)
                local station = SpaceStation():setCallSign("station"):setPosition(0, 1000)
                local filterStation = function(thing) return thing == station end
                local filterShip = function(thing) return thing == ship end
                local filterShipOrStation = function(thing) return filterStation(thing) or filterShip(thing) end

                universe:add(player, ship, station)

                -- mock chatter to easily track which chats we have seen
                local chat1 = { {ship, "one"} }
                local chat2 = { {station, "two"} }
                local chat3WithShip = { {ship, "three"} }
                local chat3WithStation = { {station, "three"} }
                local chat4 = { {station, "four"}, {ship, "four"} }
                local chat5 = { {ship, "five"}, {station, "five"} }

                local chat1Seen = 0
                local chat2Seen = 0
                local chat3SeenWithShip = 0
                local chat3SeenWithStation = 0
                local chat4Seen = 0
                local chat5Seen = 0
                local errorsSeen = 0
                local chatter = mockChatter()
                chatter.converse = function(_, conversation)
                    local pretty = require 'pl.pretty'

                    if conversation == chat1 then chat1Seen = chat1Seen + 1
                    elseif conversation == chat2 then chat2Seen = chat2Seen + 1
                    elseif conversation == chat3WithShip then chat3SeenWithShip = chat3SeenWithShip + 1
                    elseif conversation == chat3WithStation then chat3SeenWithStation = chat3SeenWithStation + 1
                    elseif conversation == chat4 then chat4Seen = chat4Seen + 1
                    elseif conversation == chat5 then chat5Seen = chat5Seen + 1
                    else
                        errorsSeen = errorsSeen + 1
                    end
                end
                assert(Chatter:isChatter(chatter))

                local noise = Chatter:newNoise(chatter)

                -- chat for ship only
                noise:addChatFactory(Chatter:newFactory(1,
                    function(one) if one == ship then return chat1  end end, {
                    filters = { filterShip }
                }), "chat1")

                -- chat for station only
                noise:addChatFactory(Chatter:newFactory(1,
                    function(one) if one == station then return chat2 end end, {
                    filters = { filterStation }
                }), "chat2")

                -- chat for station or ship
                noise:addChatFactory(Chatter:newFactory(1,
                    function(thisThing)
                        if thisThing == ship then
                            return chat3WithShip
                        elseif thisThing == station then
                            return chat3WithStation
                        end
                    end, {
                    filters = { filterShipOrStation }
                }), "chat3")

                -- chat for station and ship
                noise:addChatFactory(Chatter:newFactory(2,
                    function(one, two) if one == station and two == ship then return chat4 end end, {
                    filters = { filterStation, filterShip }
                }), "chat4")

                -- chat for ship and station
                noise:addChatFactory(Chatter:newFactory(2,
                    function(one, two) if one == ship and two == station then return chat5 end end, {
                    filters = { filterShip, filterStation }
                }), "chat5")

                for _=1,60 * 6 * 10 do Cron.tick(1) end

                -- a naive check to see if results are random
                assert.is_same(0, errorsSeen)
                assert(chat1Seen >= 2 and chat1Seen <= 25, "chat1 should occur between 1 and 25 times. Got " .. chat1Seen)
                assert(chat2Seen >= 2 and chat2Seen <= 25, "chat2 should occur between 1 and 25 times. Got " .. chat2Seen)
                assert(chat3SeenWithShip >= 1 and chat3SeenWithShip <= 12, "chat3 should occur between 1 and 25 times with ship. Got " .. chat3SeenWithShip)
                assert(chat3SeenWithStation >= 1 and chat3SeenWithStation <= 12, "chat3 should occur between 1 and 25 times with station. Got " .. chat3SeenWithStation)
                assert(chat4Seen >= 2 and chat4Seen <= 25, "chat4 should occur between 1 and 25 times. Got " .. chat4Seen)
                assert(chat5Seen >= 2 and chat5Seen <= 25, "chat5 should occur between 1 and 25 times. Got " .. chat5Seen)
            end)
        end)

        it("allows to remove chat factories", function()
            withUniverse(function(universe)
                local player = PlayerSpaceship():setCallSign("player"):setPosition(0, 0)
                local ship = CpuShip():setCallSign("ship"):setPosition(1000, 0)

                universe:add(player, ship)

                local chat1 = Chatter:newFactory(1, function(thisShip)
                    return {
                        { thisShip, "Hello World"},
                    }
                end)
                local chat2 = Chatter:newFactory(1, function(thisShip)
                    return {
                        { thisShip, "You should not see me"},
                    }
                end)

                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)
                noise:addChatFactory(chat2, "chat2")
                noise:addChatFactory(chat1, "chat1")
                noise:removeChatFactory("chat2")

                for _=1,90 do Cron.tick(1) end

                assert.is_same({
                    {ship, "Hello World"},
                }, chatter:getLastMessages())
            end)
        end)

        describe("addChatFactory()", function()
            it("allows to add a chat and returns an id", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)
                local factory = mockChatFactory()

                local id = noise:addChatFactory(factory)
                assert.is_same("string", type(id))
                assert.not_same("", id)
            end)

            it("uses an id if it given", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)
                local factory = mockChatFactory()

                local id = noise:addChatFactory(factory, "foobar")
                assert.is_same("foobar", id)
            end)

            it("fails if no chat is given", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)

                assert.has_error(function() noise:addChatFactory(nil) end)
                assert.has_error(function() noise:addChatFactory("foo") end)
                assert.has_error(function() noise:addChatFactory(42) end)
                assert.has_error(function() noise:addChatFactory({}) end)
            end)

            it("fails if the given id is not a non-empty string", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)
                local factory = mockChatFactory()

                assert.has_error(function() noise:addChatFactory(factory, "") end)
                assert.has_error(function() noise:addChatFactory(factory, 42) end)
                assert.has_error(function() noise:addChatFactory(factory, {}) end)
            end)
        end)
        describe("removeChatFactory()", function()
            it("allows to remove a chat", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)
                local factory = mockChatFactory()

                noise:addChatFactory(factory, "id")
                noise:removeChatFactory("id")
            end)
            it("allows to remove a chat when it has not been set before", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)

                noise:removeChatFactory("id")
            end)

            it("fails if the given id is not a non-empty string", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)

                assert.has_error(function() noise:removeChatFactory("") end)
                assert.has_error(function() noise:removeChatFactory(42) end)
                assert.has_error(function() noise:removeChatFactory({}) end)
            end)
        end)
        describe("getChatFactories()", function()
            it("returns all ChatFactories", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)
                local chat1 = mockChatFactory()
                local chat2 = mockChatFactory()
                local chat3 = mockChatFactory()

                noise:addChatFactory(chat1, "one")
                noise:addChatFactory(chat2, "two")
                noise:addChatFactory(chat3, "three")

                assert.is_same({
                    one = chat1,
                    two = chat2,
                    three = chat3,
                }, noise:getChatFactories())
            end)
            it("allows to remove all ChatFactories", function()
                local chatter = mockChatter()
                local noise = Chatter:newNoise(chatter)
                local chat1 = mockChatFactory()
                local chat2 = mockChatFactory()
                local chat3 = mockChatFactory()

                noise:addChatFactory(chat1, "one")
                noise:addChatFactory(chat2, "two")
                noise:addChatFactory(chat3, "three")

                for id, _ in pairs(noise:getChatFactories()) do
                    noise:removeChatFactory(id)
                end

                assert.is_same({}, noise:getChatFactories())
            end)
        end)
    end)
end)