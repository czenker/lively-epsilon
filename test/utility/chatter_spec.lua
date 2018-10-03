local function mockPlayers(...)
    local players = {...}

    -- mock getPlayerShip()
    _G.getPlayerShip = function(id)
        if id == -1 then return players[1] else return players[id] end
    end

    -- gather all comms a ship got
    for _,player in pairs(players) do
        player.shipLogs = {}
        player.addToShipLog = function(_, message, color)
            table.insert(player.shipLogs, {
                message = message,
                color = color
            })
        end
    end


end

insulate("Chatter", function()
    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("new()", function()


    end)

    describe("say()", function()
        it("works with a string as sender", function()
            local player = eePlayerMock()
            mockPlayers(player)

            local chatter = Chatter:new()
            chatter:say("John Doe", "Hello World")
            assert.is_same("John Doe: Hello World", player.shipLogs[1].message)
        end)

        it("works with a ship as sender", function()
            local player = eePlayerMock()
            local ship = eeCpuShipMock():setCallSign("John Doe")
            mockPlayers(player)

            local chatter = Chatter:new()
            chatter:say(ship, "Hello World")
            assert.is_same("John Doe: Hello World", player.shipLogs[1].message)
        end)

        it("does not send the message if the ship is invalid", function()
            local player = eePlayerMock()
            local ship = eeCpuShipMock():setCallSign("John Doe")
            ship:destroy()
            mockPlayers(player)

            local chatter = Chatter:new()
            chatter:say(ship, "Hello World")
            assert.is_same({}, player.shipLogs)
        end)

        it("sends to all player ships", function()
            local player1 = eePlayerMock()
            local player2 = eePlayerMock()
            local player3 = eePlayerMock()
            mockPlayers(player1, player2, player3)

            local chatter = Chatter:new()
            chatter:say("John Doe", "Hello World")
            assert.is_same("John Doe: Hello World", player1.shipLogs[1].message)
            assert.is_same("John Doe: Hello World", player2.shipLogs[1].message)
            assert.is_same("John Doe: Hello World", player3.shipLogs[1].message)
        end)

        it("fails when sender is nil or a number", function()
            local chatter = Chatter:new()
            assert.has_error(function()
                chatter:say(nil, "Hello World")
            end)
            assert.has_error(function()
                chatter:say(42, "Hello World")
            end)
        end)

        it("fails when message is nil or a number", function()
            local chatter = Chatter:new()
            assert.has_error(function()
                chatter:say("John Doe", nil)
            end)
            assert.has_error(function()
                chatter:say("John Doe", 42)
            end)
        end)
    end)

    describe("converse()", function()
        it("leaves breaks between the speakers", function()
            local player = eePlayerMock()
            local ship = eeCpuShipMock():setCallSign("Two")
            mockPlayers(player)
            local chatter = Chatter:new()

            chatter:converse({
                {"One", "Saying six words takes three seconds."},
                {ship, "Four words - two seconds."}
            })
            assert.is_same("One: Saying six words takes three seconds.", player.shipLogs[1].message)
            Cron.tick(1.5)
            assert.is_nil(player.shipLogs[2])
            Cron.tick(2)
            assert.is_same("Two: Four words - two seconds.", player.shipLogs[2].message)
        end)

        it("aborts conversation if one speaker got destroyed", function()
            local player = eePlayerMock()
            mockPlayers(player)
            local chatter = Chatter:new()
            local ship1 = eeCpuShipMock():setCallSign("John Doe")
            local ship2 = eeCpuShipMock():setCallSign("Jack the Ripper")

            chatter:converse({
                {ship2, "I'm gonna destroy you"},
                {ship1, "Oh no"},
                {ship2, "Wait. How did you survive that?"},
            })

            Cron.tick(1)
            assert.is_same("Jack the Ripper: I'm gonna destroy you", player.shipLogs[1].message)
            ship1:destroy()

            for i=1,10,1 do Cron.tick(1) end

            assert.is_nil(player.shipLogs[2])
        end)

        it("sends to all player ships", function()
            local player1 = eePlayerMock()
            local player2 = eePlayerMock()
            local player3 = eePlayerMock()
            mockPlayers(player1, player2, player3)

            local chatter = Chatter:new()
            chatter:converse({{"John Doe", "Hello World"}})
            assert.is_same("John Doe: Hello World", player1.shipLogs[1].message)
            assert.is_same("John Doe: Hello World", player2.shipLogs[1].message)
            assert.is_same("John Doe: Hello World", player3.shipLogs[1].message)
        end)

        it("fails when messages is nil or a string", function()
            local chatter = Chatter:new()
            assert.has_error(function()
                chatter:converse(nil)
            end)
            assert.has_error(function()
                chatter:converse("This breaks")
            end)
        end)
        it("fails if one of items in the table is not a table", function()
            local chatter = Chatter:new()
            assert.has_error(function()
                chatter:converse({
                    {"John Doe", "Hello World"},
                    "Ehm... this breaks",
                })
            end)
        end)
        it("fails if one of the senders is a number", function()
            local chatter = Chatter:new()
            assert.has_error(function()
                chatter:converse({
                    {"John Doe", "Hello World"},
                    {42, "I got the answer"},
                })
            end)
        end)
        it("fails if one of the messages is a number", function()
            local chatter = Chatter:new()
            assert.has_error(function()
                chatter:converse({
                    {"John Doe", "Hello World"},
                    {"Arthur Dent", 42},
                })
            end)
        end)
    end)

end)