insulate("documentation on Comms", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        withUniverse(function()
            local player = PlayerSpaceship()

            -- tag::basic[]
            local ship = CpuShip()
            Ship:withComms(ship)
            ship:setHailText("How can we help you?")
            ship:addComms(Comms:newReply("Who are you?", Comms:newScreen("We are a ship of the Human Navy.")))
            -- end::basic[]

            ship:openCommsTo(player)
            assert.is_same("How can we help you?", player:getCurrentCommsText())
            player:selectComms("Who are you?")
            assert.is_same("We are a ship of the Human Navy.", player:getCurrentCommsText())
        end)
    end)
    it("reply functions", function()
        withUniverse(function()
            local player = PlayerSpaceship()

            -- tag::reply-functions[]
            local station = SpaceStation()
            Station:withComms(station)

            station:setHailText(function(comms_target, comms_source)
                return "Hello " .. comms_source:getCallSign() .. ". This is " .. comms_target:getCallSign() .. ". How can we help?"
            end)

            station:addComms(Comms:newReply(
                function(self, comms_target, comms_source) -- what player says
                    if comms_target:getHull() < comms_target:getHullMax() then
                        return "Your station took damage. What is your status?"
                    else
                        return "What is your status?"
                    end
                end,
                function(self, comms_target, comms_source) -- next screen
                    if comms_target:areEnemiesInRange(10000) then
                        return Comms:newScreen("We are currently under attack.")
                    else
                        return Comms:newScreen("There are no attackers near by.")
                    end

                end,
                function(self, comms_target, comms_source) -- condition
                    return comms_source:isDocked(comms_target)
                end
            ))
            -- end::reply-functions[]

            station:setCallSign("Station"):setPosition(0, 0):setFactionId(1):setHullMax(100):setHull(100)
            player:setCallSign("Player"):setPosition(0, 0):setFactionId(1)
            local enemy = CpuShip():setCallSign("Enemy"):setPosition(99999, 0):setFactionId(2)

            player:commandOpenTextComm(station)
            assert.is_same("Hello Player. This is Station. How can we help?", player:getCurrentCommsText())
            assert.is_false(player:hasComms("Your station took damage. What is your status?"))
            assert.is_false(player:hasComms("What is your status?"))
            player:commandCloseTextComm()

            player:setDockedAt(station)

            player:commandOpenTextComm(station)
            assert.is_false(player:hasComms("Your station took damage. What is your status?"))
            player:selectComms("What is your status?")
            assert.is_same("There are no attackers near by.", player:getCurrentCommsText())
            player:commandCloseTextComm()

            station:setHull(50)

            player:commandOpenTextComm(station)
            assert.is_false(player:hasComms("What is your status?"))
            player:selectComms("Your station took damage. What is your status?")
            assert.is_same("There are no attackers near by.", player:getCurrentCommsText())
            player:commandCloseTextComm()

            enemy:setPosition(1000, 0)

            player:commandOpenTextComm(station)
            assert.is_false(player:hasComms("What is your status?"))
            player:selectComms("Your station took damage. What is your status?")
            assert.is_same("We are currently under attack.", player:getCurrentCommsText())
            player:commandCloseTextComm()
        end)
    end)
    it("screen", function()
        -- tag::guess-my-number[]
        local station = SpaceStation()
        Station:withComms(station)

        local solution = math.random(1,10)

        local correctGuessScreen = function()
            station:removeComms("guess_game")
            return Comms:newScreen("Yes, that was my number. You have won.")
        end

        local function wrongGuessScreen(number)
            return function()
                local screen = Comms:newScreen()
                screen:addText("No, " .. number .. " is not the number I was thinking of. Guess again.")

                for i=1,10 do
                    if i == solution then
                        screen:addReply(Comms:newReply(string.format("Is it %d?", i), correctGuessScreen))
                    else
                        screen:addReply(Comms:newReply(string.format("Is it %d?", i), wrongGuessScreen(i)))
                    end
                end

                return screen
            end
        end

        station:addComms(Comms:newReply("I want to play a game", function()
            local screen = Comms:newScreen("Can you guess my number?")

            for i=1,10 do
                if i == solution then
                    screen:addReply(Comms:newReply(string.format("Is it %d?", i), correctGuessScreen))
                else
                    screen:addReply(Comms:newReply(string.format("Is it %d?", i), wrongGuessScreen(i)))
                end
            end

            return screen
        end), "guess_game")
        -- end::guess-my-number[]
        local player = PlayerSpaceship()
        solution = 4 -- we fake the random number to have a stable test

        player:commandOpenTextComm(station)
        player:selectComms("I want to play a game")
        assert.is_same("Can you guess my number?", player:getCurrentCommsText())

        player:selectComms("Is it 1?")
        assert.is_same("No, 1 is not the number I was thinking of. Guess again.", player:getCurrentCommsText())
        player:selectComms("Is it 2?")
        assert.is_same("No, 2 is not the number I was thinking of. Guess again.", player:getCurrentCommsText())
        player:selectComms("Is it 3?")
        assert.is_same("No, 3 is not the number I was thinking of. Guess again.", player:getCurrentCommsText())
        player:selectComms("Is it 4?")
        assert.is_same("Yes, that was my number. You have won.", player:getCurrentCommsText())
        player:commandCloseTextComm(station)

        player:commandOpenTextComm(station)
        assert.is_false(player:hasComms("I want to play a game"))
    end)
end)