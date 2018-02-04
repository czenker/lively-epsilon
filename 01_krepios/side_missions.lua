require "01_krepios/products.lua"

local f = string.format

local salut = function()
    return Util.random({
        "Was haltet ihr von dem Angebot?",
        "Was denkt ihr?",
        "Klingt das attraktiv?",
        "Was haltet ihr davon?",
        "Denken ihr, ihr könnt mir den Gefallen tun?",
        "Könnt ihr mir den Gefallen tun?",
        "Denken ihr, ihr könnt mir helfen?",
        "Könnt ihr mir helfen?",
        "Kommen wir ins Geschäft?",
    })
end

local function randomTransportProductMission(from, to, player)
    local possibleProducts = {}
    if to:hasTag("mining") then
        possibleProducts[products.miningMachinery] = products.miningMachinery
    end
    if from:hasTag("mining") and to:hasTag("residual") then
        possibleProducts[products.ore] = products.ore
        possibleProducts[products.plutoniumOre] = products.plutoniumOre
    end
    if from:hasTag("residual") and to:hasTag("mining") then
        possibleProducts[products.o2] = products.o2
        possibleProducts[products.power] = products.power
        possibleProducts[products.water] = products.water
    end

    local product = Util.random(possibleProducts)
    if product == nil then return nil end

    local minAmount = math.floor(player:getMaxStorageSpace() / product:getSize() * 0.4)
    local maxAmount = math.ceil(player:getMaxStorageSpace() / product:getSize() * 1.2) -- give incentive to increase storage space
    local amount = math.random(minAmount,maxAmount)
    if amount == 0 then return nil end

    local payment = amount * product.basePrice * 0.2 * (1 + distance(from, to)/40000)
    local penalty = amount * product.basePrice * 1.5
    local mission

    mission = Missions:transportProduct(from, to, product, {
        amount = amount,
        acceptCondition = function(self, error)
            if error == "no_storage" then
                return "Ihr Schiff hat keinen Laderaum. Ich hoffe, Sie haben Verstaendnis, dass wir diesen Auftrag darum nicht an Sie vergeben werden."
            elseif error == "small_storage" then
                return f("Es tut uns sehr leid, aber der Laderaum Ihres Schiffes ist leider zu klein um diesen Auftrag anzunehmen. Sie benötigen mindestens einen Laderaum von %d.", amount * product:getSize())
            elseif self:getPlayer():getReputationPoints() < penalty then
                return "Sie sind im Augenblick nicht in der Lage die Kaution zu uebernehmen. Wir koennen diesen Auftrag darum leider nicht an Sie uebergeben."
            end
            return true
        end,
        onAccept = function(self)
            self:getPlayer():addReputationPoints(-1 * penalty)
            local hint = f("Docken Sie an %s um  %s aufzunehmen", from:getCallSign(), product:getName())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        onLoad = function(self)
            self:getPlayer():addToShipLog(f("%s aufgenommen", product:getName()), "255,127,0")
            local hint = f("Docken Sie an %s um %s auszuladen", to:getCallSign(), product:getName())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
            if Station:hasStorage(from) and from:canStoreProduct(product) then
                from:modifyProductStorage(product, -1 * amount)
            end
        end,
        onUnload = function(self)
            if Station:hasStorage(to) and to:canStoreProduct(product) then
                to:modifyProductStorage(product, amount)
            end
        end,
        onInsufficientStorage = function(self)
            mission:getPlayer():addToShipLog(f("Laderaum zu klein um %s aufzunehmen. %d benötigt.", product:getName(), amount * product:getSize()))
        end,
        onProductLost = function(self)
            self:getMissionBroker():sendCommsMessage(self:getPlayer(), f("Nun gut. Sie haben die Waren verkauft. Wie vertraglich vereinbart behalten wir daher die Kaution in Höhe von %0.2fRP ein.", penalty))
        end,
        onSuccess = function(self)
            self:getPlayer():addToShipLog(f("%s ausgeliefert. Mission abgeschlossen", product:getName()), "255,127,0")
            self:getMissionBroker():sendCommsMessage(self:getPlayer(), f("Vielen Dank fuer die Lieferung. Wir haben Ihnen die Bezahlung in Höhe von %0.2fRP sowie die Kaution ueberwiesen. Wenn Sie wieder einen Auftrag suchen melden Sie sich bei uns.", payment))
            self:getPlayer():addReputationPoints(payment + penalty)
        end,
        onFailure = function(self)
            self:getPlayer():addToShipLog(f("Auslieferung von %s gescheitert", product:getName()), "255,127,0")
        end,
    })
    Mission:withBroker(mission, f("Bringen Sie %d Einheiten %s nach %s", amount, product:getName(), to:getCallSign()), {
        description = f("Unsere Kollegen von %s haben uns gebeten ihnen eine Ladung %s zu schicken.\n\nWir suchen daher einen Kurier, der %d Einheiten %s ausliefern kann. Wir zahlen für die Auslieferung %0.2fRP. Ausserdem erheben wir eine Kaution in Hoehe von %0.2fRP - nur fuer den Fall, dass sie auf die Idee kommen sollten unsere Waren auf dem freien Markt zu verkaufen.", to:getCallSign(), product:getName(), amount, product:getName(), payment, penalty),
        acceptMessage = "Vielen Dank, dass sie den Auftrag annehmen.",
    })
    Mission:withTags(mission, "transport")

    return mission
end

local function randomBuyerMission(station, product)
    local person = Person:newHuman()
    local amount = math.floor(station:getMaxProductStorage(product) * (math.random() * 0.15 + 0.1))

    local paymentPerUnit = product.basePrice * (math.random() * 0.2 + 1.2)
    local paymentBonus = product.basePrice * (math.random() * 0.15 + 0.1) * amount

    local hint = function(remainingAmount)
        local units
        if remainingAmount > 1 then
            units = remainingAmount .. " Einheiten"
        else
            units = "eine Einheit"
        end
        return f("Bringen Sie %s %s nach %s.", units, product:getName(), station:getCallSign())
    end

    local mission = Missions:bringProduct(station, {
        product = product,
        amount = amount,
        onStart = function(self)
            local hint = hint(amount)
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        commsLabel = f("Mit %s sprechen", person:getFormalName()),
        sellProductScreen = function(self, screen, player, info)
            if info.justBroughtAmount > 0 then
                screen:addText(Util.random({
                    f("%d Einheiten %s erhalten, %0.2fRP überwiesen.", info.justBroughtAmount, product:getName(), info.justBroughtAmount * paymentPerUnit),
                }))
            else
                screen:addText(f(Util.random({
                    "Hey, denkt ihr an die Einheiten %s?",
                    "Ihr habt noch nicht alle Einheiten %s geliefert.",
                }), self:getProduct():getName()))
            end
            screen:addText("\n\n" .. f(Util.random({
                "Es fehlen noch %d Einheiten.",
            }), info.remainingAmount) .. " " .. f(Util.random({
                "Und denkt an den Bonus von %0.2fRP, den ich euch zahle, sobald die Lieferung komplett ist"
            }), paymentBonus) .. ".")
            if player:isDocked(station) then
                if info.maxAmount > 0 then
                    local label
                    if info.maxAmount == 1 then label = "1 Einheit" else label = f("%d Einheiten", info.maxAmount) end
                    screen:withReply(Comms.reply(label .. " verkaufen", info.link(info.maxAmount)))
                end
                for _,i in ipairs({20,5,1}) do
                    if i < info.maxAmount then
                        local label
                        if i == 1 then label = "1 Einheit" else label = f("%d Einheiten", i) end
                        screen:withReply(Comms.reply(label .. " verkaufen", info.link(i)))
                    end
                end
            end
            screen:withReply(Comms.reply("zurück"))
        end,
        onDelivery = function(self, amount, player)
            player:addReputationPoints(amount * paymentPerUnit)
            self:setHint(hint(self:getTotalAmount() - self:getBroughtAmount()))
        end,
        successScreen = function(self, screen, player)
            screen:addText(Util.random({
                f("Das war die letzte Ladung %s, die ihr liefern solltet.", product:getName()),
                f("Die letzte Lieferung %s ist angekommen.", product:getName()),
            }) .. " " .. Util.random({
                "Vielen Dank für die schnelle Lieferung."
            }) .. " " .. Util.random({
                f("Wie versprochen habe ich euch zusätzlich den Bonus in Höhe von %0.2fRP überwiesen.", paymentBonus),
            })
            )
        end,
        onSuccess = function(self)
            self:getPlayer():addReputationPoints(paymentBonus)
        end,
    })

    Mission:withBroker(mission, product:getName() .. " besorgen", {
        description = Util.random({
            f("Mein Name ist %s.", person:getFormalName()),
            f("Sie sprechen mit %s.", person:getFormalName()),
            f("%s ist mein Name.", person:getFormalName()),
        }) .. "\n\n" .. Util.random({
            f("Könnt ihr für mich %d Einheiten %s organisieren?", amount, product:getName()),
            f("Ich bin auf der Suche nach %d Einheiten %s.", amount, product:getName()),
            f("Ich brauche einen Händler, der mir %d Einheiten %s besorgen kann.", amount, product:getName()),
            f("Ihr könntet mir dabei helfen, %d Einheiten %s zu besorgen.", amount, product:getName()),
        }) .. " " .. Util.random({
            f("Ich zahle gut - %0.2fRP pro gelieferte Einheit und noch einmal %0.2fRP als Bonus, wenn alles geliefert ist.", paymentPerUnit, paymentBonus),
        }) .. "\n\n" .. salut(),
        acceptMessage = Util.random({
            f("Sehr gut. Ich warte hier auf euch und auf die Einheiten %s.", product:getName())
        }) .. " " .. Util.random({
            "Es ist mir egal, woher ihr das Zeug besorgt, Hauptsache ich muss nicht ewig warten."
        }),
    })

    Mission:forPlayer(mission)
    Mission:withTags(mission, "transport")

    return mission

end

local function randomTransportHumanMission(from, to)
    local person = Person:newHuman()
    local payment = distance(from, to)/2000 * (math.random() * 0.4 + 0.8)

    local hail = Util.random({
        "Hallo",
        "Servus",
        "Guten Tag",
        "Seien Sie gegrüßt",
    }) .. ". " .. f(Util.random({
        "Mein Name ist %s.",
        "Sie sprechen mit %s.",
        "%s ist mein Name.",
    }), person:getFormalName())

    local stories = {}

    if to:hasTag("mining") then
        local rnd = Util.random({
            {"Cheftechniker", {
                "bei der Rekalibrierung der Bohrköpfe zu helfen",
                "das Abwärmeproblem in der Bohrmechanik zu lösen",
                "den Spritverbrauch der Bohrschiffe zu überprüfen",
                "die Steuerelektronik der autonomen Drohnen zu optimieren",
            }},
            {"Chemiker", {
                "die Qualität des Erzes zu untersuchen",
                "chemische Untersuchungen an Asteroiden vorzunehmen",
                "Gestein auf Verunreinigungen hin zu untersuchen",
            }},
            {"Executive Officer", {
                "die Rentabilität der Station einzuschätzen",
                "Verbesserungen in den Arbeitsabläufen vorzunehmen",
                "Über Neuinvestitionen zu verhandeln",
            }},
        })

        local role, tasks = rnd[1], rnd[2]

        table.insert(stories, hail .. " " .. f(Util.random({
            "Ich arbeite als %s bei der Saiku Mining Corporation und wurde von",
            "Als %s bei der Saiku Mining Corporation wurde ich von",
            "In meinem Beruf als %s bei der Saiku Mining Corporation wurde ich von",
            "Ich bin als %s bei der Saiku Mining Corporation angestellt. Heute morgen wurde ich von",
            "Ich bin %s bei der Saiku Mining Corporation. Gestern abend wurde ich von",
        }), role) .. " " .. to:getCallSign() .. " " ..
        Util.random({
            "angefordert, um",
            "beauftragt",
        }) .. " " .. Util.random(tasks) .. ". " .. Util.random({
            "Leider habe ich mein Shuttle zur Station verpasst und nun muss ich mich nach Alternativen umschauen.",
            "Aufgrund eines Zwischenfalls in der Familie ist mein Pilot heute verhindert.",
            "Heute habe ich verschlafen. Eigentlich passiert mir das sonst nie, aber jetzt bin ich in einer Zwickmühle.",
        }) .. "\n\n" .. f(Util.random({
            "Ich bin bereit %0.2fRP zu zahlen, wenn Sie mich zur Arbeit bringen.",
            "Zur Arbeit gebracht zu werden wäre mir %0.2fRP wert.",
        }), payment) .. "\n\n" .. salut())
    end

    table.insert(stories, hail .. " " .. f(Util.random({
        "Ich bin auf der Suche nach einer Mitfluggelegenheit nach %s.",
        "Fliegen Sie nach %s?",
        "Können Sie mich zur Station %s mitnehmen?",
        "Sie kommen nicht zufälligerweise an der Station %s vorbei, oder?",
    }) .. " " .. f(Util.random({
        "Eine Bezahlung wäre natürlich auch drin. %0.2fRP würde ich springen lassen.",
        "Für ihr Umstände würde ich %0.2fRP bezahlen.",
        "Ihre Hilfe ist mir %0.2fRP wert.",
        "Ich habe %0.2fRP - die würde ich ihnen im Gegenzug bezahlen.",
    }), payment), to:getCallSign()) .. "\n\n" .. salut())

    local title = Util.random({
        f("Personentransport nach %s", to:getCallSign()),
        f("Bringe Person nach %s", to:getCallSign()),
    })

    local description = Util.random(stories)

    local mission = Missions:transportToken(from, to, {
        onAccept = function(self)
            local hint = f("Docken Sie an %s um %s abzuholen", from:getCallSign(), person:getFormalName())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        onLoad = function(self)
            self:getPlayer():addToShipLog(f("%s ist an Board gekommen", person:getFormalName()), "255,127,0")
            local hint = f("Bringen Sie %s nach %s", person:getFormalName(), to:getCallSign())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        onSuccess = function(self)
            self:getPlayer():addToShipLog(f("%s ist am Zielort angekommen. Mission abgeschlossen", person:getFormalName()), "255,127,0")
            self:getMissionBroker():sendCommsMessage(self:getPlayer(), f("Vielen Dank, dass sie mich nach %s gebracht haben. Die ausgemachte Bezahlung von %0.2fRP habe ich Ihnen selbstverständlich soeben überwiesen.", to:getCallSign(), payment))
            self:getPlayer():addReputationPoints(payment)
        end,
        onFailure = function(self)
            self:getPlayer():addToShipLog(f("Personentransport von %s gescheitert", person:getFormalName()), "255,127,0")
        end,
    })
    Mission:withBroker(mission, title, {
        description = description,
        acceptMessage = "Vielen Dank, dass sie mich mitnehmen werden. Ich hatte schon befürchtet, dass ich hier ewig festsitzen muss.",
    })
    Mission:withTags(mission, "transport")

    return mission

end

local function randomTransportThingMission(from, to, player)
    local size = math.random()
    size = size * size + 0.2 -- ensures the size is at the lower border more oftenly
    local amount = math.ceil(size * player:getMaxStorageSpace())
    local payment = (1 + amount / 100 * 3) * distance(from, to)/2000 * (math.random() * 0.4 + 0.8)

    local possibleProducts = {}

    if from:hasTag("residual") and to:hasTag("mining") then
        table.insert(possibleProducts, {
            Product:new("Kiste Alkohol"),
            f(Util.random({
                "Mir ist zu Ohren gekommen, dass die Arbeiter auf %s zunehmend auf dem Trocknen sitzen.",
                "Ich habe gehört, den Arbeitern auf %s geht langsam ihr Alkohol aus.",
                "Haben Sie schon gehört, dass auf %s der Alkohol knapp wird?",
            }), to:getCallSign()) .. " " .. Util.random({
                "Mit einer Kiste Alkohol lässt sich dort sicher ein nettes Sümmchen verdienen.",
                "Ich wittere ein gutes Geschäft. Alles was ich tun muss ist eine Kiste feinsten Alkohol dahin liefern.",
            }) .. " " .. f(Util.random({
                "Können Sie mir helfen? Ich benötige ein Schiff, das mindestens %d Einheiten laden kann.",
                "Falls sie %d Einheiten laden können, könnten wir ins Geschäft kommen.",
            }), amount) .. " " .. f(Util.random({
                "Natürlich beteilige ich sie am Gewinn mit %0.2fRP.",
                "Wenn Sie den Transport übernehmen winken Ihnen %0.2fRP.",
            }), payment)
        })
    end
    if from:hasTag("residual") or to:hasTag("residual") then
        table.insert(possibleProducts, {
            Product:new("private Briefe"),
            f(Util.random({
                "Im Auftrag des öffentlichen Postwesens suche ich einen Kurier für einige Briefe, die auf %s sehnlichst erwartet werden.",
                "Im Auftrag des öffentlichen Postwesens suche ich einen Kurier für einige Briefe, die auf %s sehnlichst erwartet werden.",
            }), to:getCallSign()) .. " " .. f(Util.random({
                "Alles in allem brauche ich ein Schiff, das %d Einheiten laden kann.",
            }), amount) .. " " .. f(Util.random({
                "Per Tarifgesetz ist eine Zahlung von %0.2fRP als angemessene Entschädigung vorgesehen.",
            }), payment)
        })
    end
    table.insert(possibleProducts, {
        Product:new("Datenspeicher"),
        f(Util.random({
            "Wichtige Daten müssen auf die Station %s gebracht werden.",
            "Diese Datensticks müssen %s gebracht werden.",
        }), to:getCallSign()) .. " " .. Util.random({
            "Ich bin nicht befugt Ihnen zu sagen, welche Daten sich darauf befinden.",
            "Wir vertrauen auf Ihre Diskretion bei der Lieferung der Speichermedien.",
            "Die Kiste ist versiegelt und darf nur vom Empfänger geöffnet werden.",
        }) .. " " .. f(Util.random({
            "Können Sie %d Einheiten in ihrem Laderaum entbehren?",
            "Die Datensticks benötigen %d Einheiten Platz.",
        }), amount).. " " .. f(Util.random({
            "Wenn Sie an dem Auftrag interessiert sind können wir Ihnen %0.2fRP zahlen.",
            "Ihre Diskretion ist uns die Summe von %0.2fRP wert.",
        }), payment)
    })

    local thing = Util.random(possibleProducts)
    if thing == nil then return nil end
    local product, description = thing[1], thing[2]

    local mission

    mission = Missions:transportProduct(from, to, product, {
        amount = amount,
        acceptCondition = function(self, error)
            if error == "no_storage" then
                return "Ihr Schiff hat keinen Laderaum. Ich hoffe, Sie haben Verstaendnis, dass wir diesen Auftrag darum nicht an Sie vergeben werden."
            elseif error == "small_storage" then
                return f("Es tut uns sehr leid, aber der Laderaum Ihres Schiffes ist leider zu klein um diesen Auftrag anzunehmen. Sie benötigen mindestens einen Laderaum von %d.", amount * product:getSize())
            end
            return true
        end,
        onAccept = function(self)
            local hint = f("Docken Sie an %s um %s zu laden", from:getCallSign(), product:getName())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        onLoad = function(self)
            self:getPlayer():addToShipLog(f("%s geladen", product:getName()), "255,127,0")
            local hint = f("Docken Sie an %s um %s auszuliefern", to:getCallSign(), product:getName())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        onInsufficientStorage = function(self)
            mission:getPlayer():addToShipLog(f("Laderaum zu klein um %s aufzunehmen. %d benötigt.", product:getName(), amount * product:getSize()))
        end,
        onSuccess = function(self)
            self:getPlayer():addToShipLog(f("%s ausgeliefert. Mission abgeschlossen", product:getName()), "255,127,0")
            to:sendCommsMessage(self:getPlayer(), f("Vielen Dank fuer die Lieferung. Wir haben Ihnen die Bezahlung in Höhe von %0.2fRP ueberwiesen. Wenn Sie wieder einen Auftrag suchen melden Sie sich bei uns.", payment))
            self:getPlayer():addReputationPoints(payment)
        end,
        onFailure = function(self)
            self:getPlayer():addToShipLog(f("Auslieferung von %s gescheitert", product:getName()), "255,127,0")
        end,
    })
    Mission:withBroker(mission, f("Bringen Sie %s nach %s", product:getName(), to:getCallSign()), {
        description = description,
        acceptMessage = "Vielen Dank, dass sie den Auftrag annehmen.",
    })
    Mission:withTags(mission, "transport")

    return mission
end

local function randomRepair(station, from, player)

    local crewCount = math.random(
        math.max(player:getRepairCrewCount() - 2, 2),
        math.max(player:getRepairCrewCount(), 4)
    )

    local duration = math.random(600, 1200)
    local x, y = Util.onVector(from, station, math.random() * 0.6 + 0.1)

    local captain = Person:newHuman()
    local payment = distance(station, x, y)/2000 * (1 + crewCount/10) * (1 + duration / 600) * (math.random() * 0.4 + 0.8)

    local mission

    local comms = function(comms_target, comms_source)
        local screen = Comms.screen()
        local workLeft = mission:getTimeToReady() / duration

        if workLeft > 0.95 then
            screen:addText("Ist ja super, dass ihr euren Technikern so vertraut, aber sie sind gerade erst angekommen. So sehr viel ist bislang nicht passiert.")
        elseif workLeft > 0.85 then
            screen:addText("Ich habe euren Technikern das Problem gezeigt und ich denke, sie haben verstanden, was zu tun ist. Jetzt machen sie erst einmal eine Pause und bedienen sich am Alkohol aus meinem Lagerraum bevor sie mit der Arbeit anfangen.")
        elseif workLeft > 0.6 then
            screen:addText("Eure Techniker sind hart an der Arbeit und trinken Selbstgebrannten. Aber für mich als Laien ist da nicht so viel zu erkennen. Die Reparatur wird wohl noch ein ganzes Weilchen dauern.")
        elseif workLeft > 0.4 then
            screen:addText("Es geht mühsam voran. Ich glaube, die Techniker haben die Ursache für den Defekt entdeckt, aber die meiste Zeit trinken Sie. Die Hälfte der Arbeit sieht aber gemacht aus.")
        elseif workLeft > 0.2 then
            screen:addText("Die wichtigsten Systeme laufen wieder. Eure Techniker machen guten Fortschritt - und hin und wieder ein Päuschen im Lager.")
        elseif workLeft > 0.1 then
            screen:addText("Die meisten Probleme sind behoben. Hin und wieder flackert noch ein Lämpchen, aber das System funktioniert wieder. Eure Techniker feiern im Lager - sollte also demnächst mit fertig sein.")
        elseif workLeft > 0 then
            screen:addText("Es sieht wieder alles gut aus. Eure Techniker waschen sich gerade noch die Hände und stoßen mit Selbstgebranntem an. Sie sollten jeden Augenblick fertig sein.")
        else
            screen:addText(f("Eure Techniker haben gute Arbeit geleistet. Alle Systeme sind wieder online.\n\nIhr könnt eure Techniker jederzeit wieder abholen.\n\nIch bin auf dem Weg zur Station %s. Fliegt bis auf 1u an mein Schiff heran, damit euer Engineer eure Kollegenzurück holen kann.", station:getCallSign()))
        end

        screen:withReply(Comms.reply("back"))

        return screen
    end
    local commsId

    local description = "Ein Schiff älteren Baujahrs."
    local descriptionBroken = "Es scheint sich nicht zu bewegen."

    mission = Missions:crewForRent(function()
        local rnd = math.random(1, 5)
        local ship = CpuShip():setTemplate(Util.random({
            "Personnel Freighter " .. rnd,
            "Goods Freighter " .. rnd,
            "Garbage Freighter " .. rnd,
            "Equipment Freighter " .. rnd,
            "Fuel Freighter " .. rnd,
            "MT52 Hornet",
            "MU52 Hornet",
            "Adder MK4",
            "Adder MK5",
            "Adder MK6",
        })):setFaction("Independent"):setPosition(x, y):orderIdle()
        ship.original_speed = ship:getImpulseMaxSpeed()

        ship:setImpulseMaxSpeed(0):setJumpDrive(false):setWarpDrive(false)
        Ship:withCaptain(ship, captain)

        Ship:withComms(ship)
        local hail = Util.random({
            "Ihr habt die Techniker für mein Problem an Board?",
            "Ihr bringt die Techniker für das Problem?",
            "Ah, ihr habt die Techniker an Board.",
        }) .. " Fliegt bitte " .. Util.random({
            "bis auf 1u",
            "dicht",
            "sehr nah",
        }) .. " an mein Schiff heran, dann kann euer Engineer die " .. Util.random({"Kollegen", "Techniker", "Ingenieure", "Reparaturmitarbeiter"}) .. " rüber schicken."
        ship:setHailText(function(ship, player)
            return humanShipHail(ship, player) .. "\n\n" .. hail
        end)
        commsId = ship:addComms(Comms.reply("Wie laufen die Reparaturen?", comms, function() return mission:getRepairCrewCount() > 0 end))

        ship:setDescriptions(
            description .. " " .. descriptionBroken,
            description .. " " .. descriptionBroken .. " Die Scans des Laderaums zeigen erhöhte Ethanolwerte."
        )
        return ship
    end, {
        acceptCondition = function()
            if player:getRepairCrewCount() < crewCount then
                return "Öhm, eure Crew erscheint mir etwas mickrig. Ich denke, ich suche jemand anderes."
            end
            return true
        end,
        onStart = function(self)
            local hint = f("Fliegen Sie sehr dicht an %s in Sektor %s. Ihr Engineer kann die Crew dann herüber senden.", self:getNeedy():getCallSign(), self:getNeedy():getSectorName())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        crewCount = crewCount,
        duration = duration,
        sendCrewLabel = f("%d Techniker schicken", crewCount),
        sendCrewFailed = function(self)
            self:getPlayer():addCustomMessage("engineering", "info", f("Eure Crew ist zu klein. Mindestens %d Techniker werden benötigt.", crewCount))
        end,
        onCrewArrived = function(self)
            self:getNeedy():setHailText(humanShipHail)
            self:getNeedy():sendCommsMessage(player, Util.random({
                "Super. Die Techniker sind an Board eingetroffen.",
                "Hervorragend. Eure Techniker sind so eben eingetroffen.",
                "Vielen Dank. Die Techniker sind da.",
            }) .. "\n\n" .. Util.random({
                "Ich verstehe allerdings nicht, warum sie sofort meinen Lagerraum aufgesucht haben.",
                "Irgendwie sind sie zielstrebig in den Lagerraum marschiert. Ich verstehe das nicht, aber ich bin ja auch kein Experte.",
                "Sie sind jetzt erst mal im Lagerraum zur \"Inspektion\", wie sie sagen.",
            }) .. " Aber wie auch immer... " .. Util.random({
                "ich informiere euch, wenn die Arbeit erledigt ist",
                "ich sage Bescheid, sobald die Maschine wieder läuft",
                "ich melde mich, wenn alles fertig ist"
            }) .. ".")

            local hint = f("Warten Sie, bis die Reparaturen auf %s abgeschlossen sind. Das kann einige Minuten dauern. ", self:getNeedy():getCallSign())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")

            self:getNeedy():setDescriptions(
                description .. " " .. descriptionBroken,
                description .. " " .. descriptionBroken .. " Die Stimmung an Board scheint ausgelassen zu sein und der Verdacht liegt nahe, dass die Abnahme der Ethanolkonzentration an Board in Verbindung steht."
            )
        end,
        onCrewReady = function(self)
            Tools:ensureComms(self:getNeedy(), self:getPlayer(), f(Util.random({
                "Hier ist nochmal %s.",
                "Ich bin es noch einmal, Captain %s.",
            }), captain:getFormalName()) .. "\n\n" .. Util.random({
                "Eure Techniker haben volle Arbeit geleistet",
                "Eine fähige Crew, die ihr da habt",
            }) .. " - " .. Util.random({
                "mein Schiff ist wieder voll funktionsfähig",
                "alle Systeme laufen wieder",
                "die alte Mühle ist fast wieder wie neu",
                "sie haben das Problem behoben",
            }) .. ". " .. f(Util.random({
                "Ich mache mich wieder auf den Weg nach %s",
                "Ich fliege weiter zur Station %s",
                "Die Station %s wird sich freuen, dass ich mich jetzt wieder auf den Weg mache",
            }), station:getCallSign()) .. ". " .. Util.random({
                "Fangt mich unterwegs ab",
                "Wir können uns unterwegs treffen",
            }) .. " oder " .. Util.random({
                "wir treffen uns an der Station",
                "wir treffen uns da",
                "ich warte an der Station auf euch"
            }) .. ". " .. Util.random({
                "Bitte beeilt euch",
                "Lasst euch nicht zu viel Zeit",
            }) .. ", denn " .. Util.random({
                "der Alkohol geht zur Neige",
                "mein selbstgebrannter Alkohol wird knapp",
                "meine Alkoholvorräte sind fast leer"
            }) .. " und ich " .. Util.random({"habe Angst", "befürchte"}) .. ", dass " .. Util.random({
                "die Stimmung kippt",
                "die Stimmung nicht mehr lange hält",
                "die Stimmung demnächst umschwingt",
            }) .. ".")
            self:getNeedy():setImpulseMaxSpeed(self:getNeedy().original_speed or 60)
            if station:isValid() then self:getNeedy():orderDock(station) end

            local hint = f("Holen Sie Ihre Techniker von %s ab. Das Schiff befindet sich auf dem Weg zur Station %s.", self:getNeedy():getCallSign(), station:getCallSign())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")

            self:getNeedy():setDescriptions(
                description,
                description .. " Die Systeme scheinen jedoch erst vor kurzem überholt worden zu sein."
            )
        end,
        returnCrewLabel = f("%d Techniker holen", crewCount),
        onCrewReturned = function(self)
            self:getNeedy():setHailText(function(ship, player)
                return humanShipHail(ship, player) .. Util.random({
                    "Danke noch einmal für eure Hilfe.",
                    "Eure Techniker haben gute Arbeit geleistet",
                }) .. ". " .. Util.random({
                    "Das Schiff flutscht wieder wie ein schleimiger Finanzberater"
                }) .. "."
            end)

            self:getPlayer():addReputationPoints(payment)
            self:getPlayer():addToShipLog("Mission abgeschlossen", "255,127,0")
            self:getNeedy():sendCommsMessage(self:getPlayer(), Util.random({
                "Eure Techniker haben ganze Arbeit geleistet",
                "Ihr habt da eine feine Crew",
            }) .. ". " .. f(Util.random({
                "Hier habt ihr wie versprochen die %0.2fRP."
            }), payment))
            if isString(commsId) then self:getNeedy():removeComms(commsId) end
        end,
        onSuccess = function(self)
            if station:isValid() then self:getNeedy():orderDock(station) end

            -- despawn ship a certain time after it reached its destination
            local cronId = Util.randomUuid()
            Cron.regular(cronId, function()
                if not station:isValid() or not self:getNeedy():isValid() or self:getNeedy():isDocked(station) then
                    Cron.once(cronId, function()
                        if self:getNeedy():isValid() then self:getNeedy():destroy() end
                    end, 60)
                end
            end, 5)
        end,
        onDestruction = function(self)
            local text
            if self:getRepairCrewCount() > 0 then
                text = "Das Schiff auf das ihr eure Techniker ausgeliehen habt ist von unserem Schirm verschwunden. Eure"
            else
                text = "Das Schiff auf das ihr eure Techniker ausleihen solltet ist von unserem Schirm verschwunden. Die"
            end
            Tools:ensureComms(station, self:getPlayer(), text .. " Crew wird wohl nicht wieder auftauchen. Ist scheiße, aber so ist das Leben hier draußen. Leben und Sterben liegen dicht beeinander.")
        end,
    })

    local problem = Util.random({
    })

    Mission:withBroker(mission, "Techniker ist verständigt", {
        description = f(Util.random({
            "Hey, ich bin %s, Captain eines Raumschiffs"
        }), captain:getFormalName()) .. ".\n\n" .. Util.random({"Aufgrund", "Wegen"}) .. " " .. Util.random({
            "eines Kurzschluss im System",
            "einer Überlastung des Reaktors",
            "des Auslaufs von Kühlmittel",
        }) .. " " .. Util.random({
            "ist ein Großteil meiner Systeme ausgefallen",
        }) .. ". " .. Util.random({
            "Ich benötige professionelle Hilfe bei der Reparatur",
            "Allein schaffe ich es nicht den Fehler zu beheben",
            "Ich habe keine Ahnung von Raumschiffreparatur und bin auf Hilfe angewiesen",
            "Die Schäden übersteigen meine technischen Fähigkeiten"
        }) .. ". " .. f(Util.random({
            "Ich bin auf dem Flug von %s nach %s stecken geblieben.",
            "Ich war auf dem Flug von %s nach %s als das Problem auftrat.",
            "Eigentlich wollte ich entspannt von %s nach %s fliegen und dann passiert so etwas.",
            "Ich war noch nicht lange von %s abgedockt als ich die Probleme bemerkte. Jetzt komme ich nicht bis %s.",
        }), from:getCallSign(), station:getCallSign()) .. "\n\n" .. f(Util.random({
            "Könnt ihr mir %d eurer Techniker ausleihen?",
            "Mit Unterstützung von %d Technikern bekomme ich das Problem sicher in Griff.",
            "Könnt ihr zeitweise %d eurer Techniker entbehren um mich zu unterstützen?",
        }), crewCount) .. " " .. f(Util.random({
            "%0.2fRP zahle ich für Hilfe.",
            "Eure Hilfe ist mir %0.2fRP wert.",
            "Sobald das Problem behoben ist bekommt ihr eure Techniker zurück und ich lege %0.2fRP drauf.",
            "Für %0.2fRP?",
        }), payment),
        acceptMessage = Util.random({
            "Hervorragend",
            "Ganz ausgezeichnet",
            "Großartig",
        }) .. ". " .. Util.random({
            "Kommt zum Rendevous Punkt",
            "Trefft mich auf meinem Schiff",
        }) .. ". " .. Util.random({
            "Ich, ähm... warte hier auf euch.",
            "Keine Angst, ich fliege nicht weg.",
            "Ich werde einfach hier auf euch warten - gezwungenermaßen.",
        }),
    })

    Mission:withTags(mission, "transport")

    return mission
end

local function randomKraylorBase(station, x, y, player)
    local playerDps = Util.totalLaserDps(player) * 2 -- account for tubes
    if playerDps < 1 then return nil end

    local difficulty = math.random(1,5)
    local payment = (distance(station, x, y)/2000 + difficulty * 100) * (math.random() * 0.4 + 0.8)

    local sectorName = Util.sectorName(x, y)

    -- make the station destroyable in reasonable time or it gets boring
    local stationShield = (math.random() * 0.4 + 0.8) * playerDps * 25
    local stationHull = (math.random() * 0.4 + 0.8) * playerDps * 25

    local mission = Missions:destroy(function()
        local station = KraylorSpaceStation():setTemplate("Small Station"):setPosition(x, y):setHullMax(stationHull):setHull(stationHull):setShieldsMax(stationShield):setShields(stationShield):setDescription(
            "Eine Baustelle der Piraten. Die Station ist noch nicht funktionsfähig und kaum über den Rohbau hinaus."
        )
        local ships = {}
        if difficulty == 1 then
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("MT52 Hornet")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("MT52 Hornet")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("MU52 Hornet")))
        elseif difficulty == 2 then
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("MT52 Hornet")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Adder MK6")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Adder MK6")))
        elseif difficulty == 3 then
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Piranha F12")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Adder MK6")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Adder MK6")))
        elseif difficulty == 4 then
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Piranha F12")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Nirvana R5")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Adder MK6")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Adder MK6")))
        elseif difficulty == 5 then
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Piranha F12")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Nirvana R5")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Nirvana R5")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Adder MK6")))
            table.insert(ships, KraylorCpuShip(CpuShip():setTemplate("Adder MK6")))
        end
        for _,ship in pairs(ships) do
            Util.spawnAtStation(station, ship)
            ship:orderDefendTarget(station)
        end
        table.insert(ships, station)
        return ships
    end, {
        acceptCondition = function(self, error)
            if distance(player, x, y) < 15000 then
                return "Sie halten sich zu nah am Zielgebiet auf. Wir wollen Sie nicht unnötig gefährden. Bitte halten Sie mehr Abstand um den Auftrag anzunehmen."
            end
            return true
        end,
        onStart = function(self)
            local hint = f("Finden Sie die Station im Sektor %s", sectorName)
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        onDestruction = function(self, enemy)
            local numShips, numStations = 0, 0
            for _, thing in pairs(self:getValidEnemies()) do
                if isEeStation(thing) then numStations = numStations + 1
                elseif isEeShip(thing) then numShips = numShips + 1
                end
            end
            if isEeShip(enemy) then
                if numShips == 0 then
                    self:getPlayer():addToShipLog("Abschuss des letzten Verteidigers bestätigt", "255,127,0")
                else
                    self:getPlayer():addToShipLog("Abschuss bestätigt", "255,127,0")
                end
            elseif isEeStation(enemy) then
                self:getPlayer():addToShipLog("Abschuss der Station bestätigt", "255,127,0")
            end

            local hint
            if numShips > 0 then
                if numStations > 0 then
                    local shipsText
                    if numShips > 1 then shipsText = f("%d Schiffe", numShips) else shipsText = "ein Schiff" end
                    hint = f("Es müssen noch %s und eine Station zerstört werden.", shipsText)
                elseif numShips == 1 then
                    hint = "Es muss noch ein Schiff zerstört werden."
                else
                    hint = f("Es müssen noch %d Schiffe zerstört werden.", numShips)
                end
            elseif numStations > 1 then
                hint = "Zerstören Sie die Station."
            end
            self:setHint(hint)
        end,
        onSuccess = function(self)
            station:sendCommsMessage(self:getPlayer(), f("Ihr Heldenmut hat uns vor diesem Feind geschützt. Ihre Bezahlung von %0.2fRP haben Sie sich redlich verdient.", payment))
            self:getPlayer():addReputationPoints(payment)
        end
    })

    local descriptionSize
    if difficulty == 1 then descriptionSize = "schwache"
    elseif difficulty == 2 then descriptionSize = "kleine"
    elseif difficulty == 3 then descriptionSize = "ernst zu nehmende"
    elseif difficulty == 4 then descriptionSize = "große"
    elseif difficulty == 5 then descriptionSize = "mächtige"
    end
    Mission:withBroker(mission, f("Feindstation in Sektor %s zerstören", sectorName), {
        description = f(Util.random({
            "Unsere Sensoren haben eine mögliche Feindstation im Sektor %s geortet.",
            "Unser Science Officer hat uns verdächtige Feindaktivitäten in Sektor %s gemeldet. Es sieht nach einer neuen Station aus.",
            "Wie es aussieht versuchen die Piraten einmal mehr Fuß in Sektor %s zu fassen und eine Station zu errichten.",
        }), sectorName) .. " " .. Util.random({
            "Das ist natürlich nicht hinnehmbar.",
            "Das ist für uns natürlich sehr unerfreulich.",
            "Wir sollten ihr Vorhaben schnell unterbinden.",
        }) .. " ".. f(Util.random({
            "Die Station wird von einer %sn Flotte beschützt.",
            "Um die Station ist eine %s Flotte stationiert.",
            "Der Feind lässt die Station von einer %sn Flotte beschützen.",
        }), descriptionSize) .. "\n\n" .. f(Util.random({
            "Für die Vernichtung der Station und der begleitenden Flotte ist ein Kopfgeld von %0.2fRP ausgelobt.",
            "%0.2fRP werden an den Captain bezahlt, der die Station und die Flotte vernichtet.",
        }), payment),
        acceptMessage = "Vielen Dank, dass sie den Auftrag annehmen.",
    })

    Mission:withTags(mission, "fighting")

    return mission
end

-- a mining machinery has gone rogue at should be destroyed
local function randomRagingMiner(station, x, y, player)
    local sectorName = Util.sectorName(x, y)

    local payment = (distance(station, x, y)/2000 + 70) * (math.random() * 0.4 + 0.8)
    local cause = Util.random({
        "einen Meteorideneinschlag",
        "Altersschwäche",
        "Weltraumschrott",
        "einen elektromagnetischen Impuls",
        "Korrosion",
        "radioaktive Strahlung",
        "einen Kurzschluss",
    })

    local mission = Missions:destroyRagingMiner(function()
        local ship = MyMiner(math.random(1,3))
        ship:setFaction("Kraylor"):setPosition(x, y):orderDefendLocation(x, y)
        ship:setBeamWeapon(0, 30, 0, 2000, 10, 30) -- it is slow firing, but strong
        local description = Util.random({
            "Ein alter Schürfer",
            "Ein schrottreifer Schürfer",
        }) .. ", der durch " .. cause .. "beschädigt wurde."

        ship:setDescriptions(
            description .. " Die Freund-Feind-Erkennung und die Schildgeneratoren scheinen schweren Schaden genommen zu haben. Es wird empfohlen das Schiff weiträumig zu meiden.",
            description .. " Das Schiff verursacht immensen EMP Schaden, sobald die Schilde auf 0% geladen wurden. Die Freund-Feind-Erkennung ist defekt und jedes Objekt wird als erzreicher Asteroid erkannt. Mit äußerster Vorsicht nähern."
        )
        return ship
    end, {
        acceptCondition = function(self, error)
            if distance(player, x, y) < 15000 then
                return "Ey Alter, du bist viel zu nah am Zielgebiet."
            end
            return true
        end,
        onApproach = function(self)
            station:sendCommsMessage(self:getPlayer(), "Mein Schürfer sollte jetzt auf eurem Radar zu sehen sein. Bitte seid vorsichtig. Der Laser ist extrem gefährlich und sein EMP Puls zerstört eure Schilde in Sekunden.")
        end,
        onSuccess = function(self)
            station:sendCommsMessage(self:getPlayer(), "Endlich ist " .. Util.random({
                "dieses Drecksding",
                "diese Rostlaube",
                "diese Blechkiste",
                "diese Schrottkiste",
            }) .. " " .. Util.random({
                "Vergangenheit",
                "Geschichte",
                "verschrottet worden",
            }) .. ". Diese durchgeknallte Schrottmühle hat es auch nicht anders verdient. " .. f("Hier sind ihre %0.2fRP - versaufen Sie sie nicht auf einmal.", payment))
            self:getPlayer():addReputationPoints(payment)
        end,
    })

    Mission:withBroker(mission, f("Schürfer in Sektor %s zerstören", sectorName), {
        description = Util.random({
            "Wir haben ein kleines Problemchen.",
            "Ich habe da ein delikates Problem.",
        }) .. " " .. Util.random({
            "Mein Schürfer",
            "Ich bin Schürfer und mein Raumschiff",
        }) .. " wurde durch " .. cause .. " " .. Util.random({
            "vor einigen Tagen",
            "gestern",
            "vor ein paar Stunden",
        }) .. " schwer beschädigt. Dabei sind einige Systeme ausgefallen. " .. Util.random({
            "Leider habe ich den Autopilot aktiviert",
            "Bevor ich das Schiff verlassen habe habe ich noch den Autopilot aktiviert",
        }) .. " doch jetzt " .. Util.random({
            "läuft das Schiff Amok",
            "dreht der Schrotthaufen endgültig durch",
        }) .. ". Die Freund-Feind-Erkennung " .. Util.random({
            "hat es zermatscht wie eine Raumfliege",
            "ist nur noch ein Haufen Schrott",
            "hats nicht überlebt",
            "hat den Geist aufgegeben",
        }) .. " und nun hält die AI jedes Schiff für einen Asteroiden. Der Laser ist extrem " .. Util.random({
            "gefährlich",
            "tödlich",
        }) .. ". Hinzu kommt, dass die Schilde " .. Util.random({
            "verrückt spielen",
            "einen Knacks weghaben",
            "einen Schaden haben",
            "zerfetzt wurden",
            "einen Kurzschluss haben",
        }) .. " und nicht mehr " .. Util.random({
            "starten"
        }) .. ", sondern stattdessen einen heftigen EMP Impuls aussenden. Ich brauche jemanden, der das Schrottding zerstört und dabei dachte ich an euch. " .. f("Wie klingen %0.2fRP als Belohnung?", payment),
        acceptMessage = "Yeah. Ein Zweikampf mit einer durchgeknallten Maschine. Schade, dass ich nicht zu schauen kann.",
    })

    Mission:withTags(mission, "fighting")

    return mission
end

local function randomCapture(station, x, y, player)
    local sectorName = Util.sectorName(x, y)
    local person = Person:newHuman()
    if Person:hasTags(person) and person:hasTag("male") then
        person.HeShe = "Er"
        person.heShe = "er"
    else
        person.HeShe = "Sie"
        person.heShe = "sie"
    end
    local product = Product:new(person:getFormalName(), {size = 4})
    local companionsNr = math.random(0, 2)
    local companions = {}

    local payment = (distance(station, x, y)/2000 + 75) * (1 + companionsNr * 0.2) * (math.random() * 0.4 + 0.8)

    local mission = Missions:capture(function()
        local target = KraylorCpuShip():setTemplate("Flavia Falcon"):setPosition(x, y):orderDefendLocation(x, y):setDescriptionForScanState("simple", "Schiff von " .. person:getFormalName() .. ". " .. person.HeShe .. " wird von der SMC gesucht.")
        for i=1, companionsNr do
            local ship = KraylorCpuShip():setTemplate(Util.random({
                "WX-Lindworm",
                "Adder MK4",
                "Adder MK5",
                "Adder MK6",
            }))
            Util.spawnAtStation(target, ship)
            ship:orderDefendTarget(target)
            local captain = Person:newHuman()
            local relation
            if captain:hasTag("male") then
                captain.HeShe = "Er"
                relation = Util.random({
                    "ein Kollege",
                    "ein Freund aus alten Tagen",
                    "ein Schulfreund",
                    "ein Cousin",
                })
            else
                captain.HeShe = "Sie"
                relation = Util.random({
                    "eine Kollegin",
                    "eine Freundin aus alten Tagen",
                    "eine Schulfreundin",
                    "eine Cousine",
                })
            end
            Ship:withCaptain(ship, captain)
            ship:setDescriptionForScanState("simple", f("Dieses Schiff wird von %s geflogen. %s ist %s von %s.", captain:getFormalName(), captain.HeShe, relation, person.getFormalName()))

            table.insert(companions, ship)
        end
        return target
    end, {
        acceptCondition = function(self, error)
            if distance(player, x, y) < 15000 then
                return "Ey Alter, du bist viel zu nah am Zielgebiet."
            end
            return true
        end,
        onStart = function(self)
            local hint = f("Finden Sie %s in Sektor %s", person:getFormalName(), sectorName)
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        onApproach = function(self)
            local description = f("Sie sollten %s jetzt auf ihrem Schirm sehen. Sie müssen %s Schiff zerstören und %s Rettungskapsel bergen.",
                person:hasTag("male") and Util.random({
                    "den Verbrecher",
                    "den Kriminellen",
                }) or Util.random({
                    "die Verbrecherin",
                    "die Kriminelle",
                }),
                person:hasTag("male") and "sein" or "ihr",
                person:hasTag("male") and "seine" or "ihre"
            )
            if companionsNr > 0 then
                description = description .. " " .. f(
                    "%s ist in Begleitung, die %s bis in den Tod verteidigen wird. Diese Kollaborateure interessieren uns nicht und es steht ihnen frei, sie aus dem Äther zu blasen.",
                    person:getFormalName(),
                    person:hasTag("male") and "ihn" or "sie"
                )
            end
            station:sendCommsMessage(self:getPlayer(), description)

            local hint = f("Zerstören Sie %s um %s's Rettungskapsel aufsammeln zu können", self:getBearer():getCallSign(), person:getFormalName())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        onBearerDestruction = function(self, x, y)
            local isFirst = true
            if isTable(companions) then
                for _, companion in pairs(companions) do
                    if isFirst then
                        companion:sendCommsMessage(self:getPlayer(), "Jetzt gibt es Ärger.")
                    end
                    companion:orderAttack(self:getPlayer())
                end
            end

            local pod = Artifact():setModel("ammo_box"):allowPickup(true):setPosition(x, y)
            pod:setDescription("Die Rettungskapsel von " .. person:getFormalName())

            local hint = f("Sammeln Sie die Rettungskapsel von %s in Sektor %s ein", person:getFormalName(), pod:getSectorName())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")

            return pod
        end,
        onItemDestruction = function(self)
            station:sendCommsMessage(self:getPlayer(), f(
                "Die Rettungskapsel von %s wurde zerstört. Wir machen Ihnen keinen Vorwurf, aber ich denke Sie verstehen, dass wir jede Verwicklung in den Zwischenfall abstreiten werden. Eine Bezahlung können wir Ihnen darum auch nicht anbieten.\n\nWir betrachten Auftrag hiermit als beendet.",
                person:getFormalName()
            ))
        end,
        onPickup = function(self)
            if Player:hasStorage(self:getPlayer()) then
                self:getPlayer():modifyProductStorage(product, 1)
            end

            local hint = f("Docken Sie an der Station %s", station:getCallSign())
            self:setHint(hint)
            self:getPlayer():addToShipLog(hint, "255,127,0")
        end,
        dropOffTarget = station,
        onSuccess = function(self)
            station:sendCommsMessage(self:getPlayer(), "Vielen Dank für die Hilfe bei der Ergreifung " .. (person:hasTag("male") and Util.random({
                "des Verbrechers",
                "des Kriminellen",
            }) or Util.random({
                "der Verbrecherin",
                "der Kriminellen",
            })) .. " " .. person:getFormalName() .. ". Allzu schnell wird " .. (person:hasTag("male") and "er" or "sie") .. " die Luft der Freiheit nicht mehr atmen können. " .. f("Sie erhalten wie versprochen %0.2fRP für ihre Hilfe.", payment))
            self:getPlayer():addReputationPoints(payment)
        end,
        onEnd = function(self)
            if Player:hasStorage(self:getPlayer()) then
                self:getPlayer():modifyProductStorage(product, -9999)
            end
        end,
    })
    local companionDescription
    if companionsNr == 0 then
        companionDescription = person.HeShe .. " " .. f("wurde vor Kurzem in Sektor %s gesichtet.", sectorName)
    elseif companionsNr == 1 then
        companionDescription = f("Zuletzt wurde " .. person.heShe .. " in Begleitung in Sektor %s gesehen.", sectorName)
    else
        companionDescription = person.HeShe .. " " .. f("wurde zuletzt in Begleitung von Freunden in Sektor %s gesichtet.", sectorName)
    end

    Mission:withBroker(mission, f("Kopfgeld %s", person:getFormalName()), {
        description = f("Wir bitten um ihre Mithilfe bei der Ergreifung von %s.", person:getFormalName()) .. " " .. person.heShe .. " wird wegen " .. Util.random({
            "Diebstahl von Firmeneigentum",
            "Entwendung von Firmenbesitz",
            "Teilnahme an einem nicht genehmigten Streik",
            "Erpressung von Vorgesetzten",
            "Mitgliedschaft in einer Gewerkschaft",
            "Missachtung von Befehlen Vorgesetzter",
        }) .. " von uns gesucht. " .. companionDescription .. " " .. f("Für die Ergreifung und Überführung in unsere Obhut zahlen wir %0.2fRP.", payment),
        acceptMessage = "Sie erweisen der Corporation einen wertvollen Dienst in dem Sie uns helfen, Ordnung in diesen Saustall zu bringen und ein abschreckendes Exempel zu statuieren.",
    })

    Mission:withTags(mission, "fighting")

    return mission
end

local nextPeacefulId = 0
local nextFightingId = 0

My = My or {}
My.MissionGenerator = function(stations, player)
    return {
        randomTransportMission = function(from)
            local possibleDestinations = {}
            for _, station in pairs(stations) do
                if from ~= station then possibleDestinations[station] = station end
            end

            local to = Util.random(possibleDestinations)
            if to == nil then return nil end

            nextPeacefulId = (nextPeacefulId % 5) + 1

            if missionId == 1 then
                return randomTransportProductMission(from, to, player)
            elseif missionId == 2 then
                return randomTransportHumanMission(from, to)
            elseif missionId == 3 then
                return randomTransportThingMission(from, to, player)
            elseif missionId == 4 then
                return randomRepair(from, to, player)
            else
                local product = Util.random(from:getProductsBought())
                return randomBuyerMission(from, product)
            end
        end,
        randomFightingMission = function(from)
            local x, y = from:getPosition()
            local dx, dy
            local found = false
            while not found do
                dx, dy = vectorFromAngle(math.random(0, 360), math.random(20000, 30000))
                found = true
                for _, station in pairs(stations) do
                    if distance(station, x+dx, y+dy) < 13000 then found = false end
                end
            end

            nextFightingId = (nextFightingId % 3) + 1
            if nextFightingId == 1 then
                return randomCapture(from, x+dx, y+dy, player)
            elseif nextFightingId == 2 then
                return randomKraylorBase(from, x+dx, y+dy, player)
            else
                return randomRagingMiner(from, x+dx, y+dy, player)
            end
        end,
    }
end




