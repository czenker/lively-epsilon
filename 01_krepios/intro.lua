My = My or {}

function My.startIntro(hq, player, commander, highCommand)
    local startReputation = 100
    local reputationPenalty = 20
    local helloWorldComms5 = function(badAnswer)
        return function()
            local screen = Comms.screen()
            if badAnswer then
                startReputation = startReputation - reputationPenalty
                screen:addText("Eh, ihr seid vielleicht ein paar nervige Zecken. ")
            else
                screen:addText("Ja, gute Idee. ")
            end

            screen:addText("Ich habe noch eine Verabredung mit meinen drei Freunden Johnny, Jack und Jimmy an der Bar.\n\nHaut ab, und wenn ihr ein Problem habt... lasst mich damit in Ruhe.")
            player:setReputationPoints(startReputation)
            Tools:endStoryComms()

            return screen
        end
    end
    local helloWorldComms4 = function(badAnswer)
        return function()
            local screen = Comms.screen()
            if badAnswer then
                startReputation = startReputation - reputationPenalty
                screen:addText("Wir sind hier nicht bei der Wohlfahrt, Maedchen! Hier wohnen Menschen, die dir die Kehle aufschlitzen um sich einen Drink leisten zu koennen. RP musst du dir hier selbst erarbeiten.\n\n")
            else
                screen:addText("Viele sind hier auf der Suche nach Arbeit. Die meisten sind Schuerfer, aber ein paar andere Aufgaben gibt es hier auch noch.\n\n")
            end

            screen:addText("Am besten schaut ihr mal bei den umliegenden Stationen im Asteroidenguertel vorbei. Dort gibt es gelegentlich Autraege. Und wenn ihr auf dem Weg zu ihnen seid, nehmt Wasser und Baumaschinen mit - das brauchen die dort immer.")
            :withReply(Comms.reply("Eine Frage haetten wir noch", helloWorldComms5(true)))
            :withReply(Comms.reply("Ok, wir machen uns dann mal auf dem Weg", helloWorldComms5(false)))

            return screen
        end
    end

    local helloWorldComms3 = function(badAnswer)
        return function()
            local screen = Comms.screen()
            if badAnswer then
                startReputation = startReputation - reputationPenalty
                screen:addText("[sarkastisch] Ja natuerlich hat sich der feine Herr was dabei gedacht. Unsere Situation laesst sich ja hervorragend aus ein paar 1000u einschaetzen.\n\n")
            else
                screen:addText("Nuetzlich wie ein paar Kinder, die dir am Hosenbein haengen? Ja, das bestimmt.\n\n")
            end

            screen:addText("Mit der Drecksmuehle, die ihr fliegt werdet ihr sicher nicht lange Freude haben, wenn ihr sie nicht etwas auf Vordermann bringt. Mit ein paar RP sollte da was zu machen sein. Dann kann ich mit euch vielleicht auch was anfangen.")
            :withReply(Comms.reply("Wie kommen wir hier an RP", helloWorldComms4(false)))
            :withReply(Comms.reply("Koennen wir uns von ihnen Geld leihen", helloWorldComms4(true)))

            return screen
        end
    end
    local helloWorldComms2 = function(badAnswer)
        return function()
            local screen = Comms.screen()
            if badAnswer then
                startReputation = startReputation - reputationPenalty
                screen:addText("Oh mein Gott. Natuerlich seid ihr keine Gruenschnaebel, sondern ein Haufen Heulsusen. Wegen mir koennt ihr auch zu " .. highCommand:getFormalName() .. " rennen, wenn ihr mit dem Umgangston hier nicht klar kommt.\n\n")
            else
                screen:addText("Hah. So wie ihr redet habt ihr an der Akademie den Streber-Kurs mit Bravour bestanden. Das koennt ihr euch hier gleich abgewoehnen, euer Gelaber interessiert hier niemanden.\n\n")
            end

            screen:addText("Aber mal zum Punkt: Mir ist es scheissegal, ob ihr hier seid oder nicht. Ich brauch euch nicht, ich habe euch nicht angefordert. " .. highCommand:getFormalName() .. " hielt es fuer eine gute Idee euch hier her zu schicken, weil wir hier so weit draussen sind und bestimmt Hilfe brauchen. Als ob wir hier nicht allein klar kaemen.")
            :withReply(Comms.reply(highCommand:getFormalName() .. " wird sich etwas dabei gedacht haben", helloWorldComms3(true)))
            :withReply(Comms.reply("Vielleicht koennen wir uns ja doch als nuetzlich erweisen", helloWorldComms3(false)))
            return screen
        end
    end
    local helloWorldComms1 = Comms.screen("Hier spricht Kommandant " .. commander:getFormalName() .. "\n\nSeid ihr die kleinen Gruenschnaebel, die " .. highCommand:getFormalName() .. " geschickt hat, um auf mich aufzupassen?")
        :withReply(Comms.reply("Jawoll Sir. Wir melden uns zum Dienst.", helloWorldComms2(false)))
        :withReply(Comms.reply("Hey, wir sind keine Gruenschnaebel!", helloWorldComms2(true))
    )

    Tools:storyComms(hq, player, helloWorldComms1)
end
