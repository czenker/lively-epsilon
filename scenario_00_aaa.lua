-- Name: Hello World
-- Description: Testing stuff
-- Type: Mission

require "src/lively_epsilon/init.lua"

products = {
    o2 = { name = "Oxygen"},
    power = { name = "Power Cells"},
    waste = { name = "Toxic Waste"},
    ore = { name = "Ore"},
    plutoniumOre = { name = "Plutonium Ore"},
}

for k, v in pairs(products) do
    v.id = k
    if not Product.isProduct(v) then
        error ("Product with id " .. k .. " is not valid.", 2)
    end
end


function MySpaceStation(template)
    local station = SpaceStation():setTemplate(template)
    Station:withComms(station)
    station:setHailText("Hello World")
    return station
end

function MyCpuShip(template)
    local ship = CpuShip():setTemplate(template)

    return ship
end

function init()

    local player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(200):setImpulseMaxSpeed(250):setRotationMaxSpeed(50):setWarpDrive(true):setJumpDrive(true)

    addGMFunction("Test Missions", function()
        Player:withMissionTracker(player)
        Player:withMissionDisplay(player)

        local station1 = MySpaceStation("Large Station"):setPosition(8000, 8000):setFaction("Human Navy"):setRotation(random(0, 360)):setDescription("A herring factory")
        local station2 = MySpaceStation("Medium Station"):setPosition(-8000, 8000):setFaction("Human Navy"):setRotation(random(0, 360))

        -- Herring mission
        local herringMission = Missions:transportToken(station1, station2, {
            onLoad = function(self) self:getPlayer():addToShipLog("Red Herring loaded", "0,255,255") end,
            onUnload = function(self)
                self:getPlayer():addToShipLog("Red Herring unloaded", "0,255,255")
            end,
            onSuccess = function(self)
                self:getPlayer():addReputationPoints(100)
            end,
        })
        Mission:withBroker(herringMission, "Fly red herring from " .. station1:getCallSign() .. " to " .. station2:getCallSign(), {
            description = "It is very important that the Red Herrings are shipped without harming them. We can't offer payment at the moment, but the feeling of having done a good deed should be enough of a reward.",
            acceptMessage = "Thanks for taking care of this transport mission. Please dock with our station and we will load the cargo."
        })

        local destructionMission = Missions:destroy(function()
            local enemyStation = SpaceStation():setTemplate("Small Station"):setPosition(8000, -8000):setFaction("Kraylor"):setRotation(random(0, 360))
            local ship1 = CpuShip():setTemplate("Stalker Q7"):setFaction("Kraylor"):orderDefendTarget(enemyStation)
            local ship2 = CpuShip():setTemplate("Stalker Q7"):setFaction("Kraylor"):orderDefendTarget(enemyStation)
            Util.spawnAtStation(enemyStation, ship1)
            Util.spawnAtStation(enemyStation, ship2)

            return {enemyStation, ship1, ship2}
        end, {
            onDestruction = function (self, enemy)
                local log
                if isEeStation(enemy) then
                    log = "Yes!! Their station is down. "
                    if self:countValidEnemies() > 0 then
                        log = log .. "Now just destroy their fighters."
                    end
                elseif self:countValidEnemies() > 0 then
                    log = "That is one of their fighters down."
                end
                if log ~= nil then self:getPlayer():addToShipLog(log, "0,255,255") end
            end,
            onSuccess = function(self)
                self:getPlayer():addReputationPoints(100)
            end,
        })
        Mission:withBroker(destructionMission, "Destroy enemy base", {
            description = "It has come to our knownledge that enemy forces are building a base close to our location. We can't let that happen.\n\nFortunately they are rather weak at the moment, so now is the perfect time to strike. Can you help us?",
            acceptMessage = "We are confident that you will crush our enemy."
        })

        Station:withMissionBroker(station1)
        station1:addComms("Mission Board", Comms.defaultMissionBoard)
        station1:addMission(herringMission)
        station1:addMission(destructionMission)

        removeGMFunction("Test Missions")
    end)


    addGMFunction("Test Production", function()

        local stationSolar = MySpaceStation("Medium Station"):setPosition(-5000, 10000):setFaction("Human Navy")
        local stationFabricate = MySpaceStation("Medium Station"):setPosition(0, 10000):setFaction("Human Navy")
        local stationConsume = MySpaceStation("Medium Station"):setPosition(5000, 10000):setFaction("Human Navy")
        stationSolar:addComms("Merchant", Comms.defaultMerchant)
        stationFabricate:addComms("Merchant", Comms.defaultMerchant)
        stationConsume:addComms("Merchant", Comms.defaultMerchant)

        Station:withStorageRooms(stationSolar, {
            [products.power] = 1000
        })
        Station:withMerchant(stationSolar, {
            [products.power] = { sellingPrice = 1 }
        })
        stationSolar:modifyProductStorage(products.power, 100)
        Station:withProduction(stationSolar, {
            {
                productionTime = 10,
                produces = {
                    { product = products.power, amount = 5 }
                }
            },
        })

        Station:withStorageRooms(stationFabricate, {
            [products.power] = 1000,
            [products.o2] = 1000,
            [products.waste] = 500,
        })
        Station:withMerchant(stationFabricate, {
            [products.power] = { buyingPrice = 1 },
            [products.o2] = { sellingPrice = 5 },
            [products.waste] = { sellingPrice = 0 },
        })
        stationFabricate:modifyProductStorage(products.power, 200)
        stationFabricate:modifyProductStorage(products.waste, 200)
        Station:withProduction(stationFabricate, {
            {
                productionTime = 30,
                consumes = {
                    { product = products.power, amount = 10 }
                },
                produces = {
                    { product = products.o2, amount = 10 },
                    { product = products.waste, amount = 2 },
                }
            },
        })



        Station:withStorageRooms(stationConsume, {
            [products.waste] = 500,
        })
        Station:withMerchant(stationConsume, {
            [products.waste] = { buyingPrice = 1 },
        })
        stationConsume:modifyProductStorage(products.waste, 200)
        Station:withProduction(stationConsume, {
            {
                productionTime = 5,
                consumes = {
                    { product = products.waste, amount = 1 }
                }
            },
        })

        local ship = MyCpuShip("Goods Freighter 1"):setPosition(11000, 0):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(250):setRotationMaxSpeed(50)
        Ship:withStorageRooms(ship, {
            [products.power] = 1000,
        })
        Ship:orderBuyer(ship, stationFabricate, products.power)

        removeGMFunction("Test Production")
    end)

    addGMFunction("Test Mining", function()
        local stationMine = MySpaceStation("Medium Station"):setPosition(50000, 0):setFaction("Human Navy")

        setCirclePos(Asteroid(), 70000, 0, 0, 3000)
        setCirclePos(Asteroid(), 70000, 0, 60, 3000)
        setCirclePos(Asteroid(), 70000, 0, 120, 3000)
        setCirclePos(Asteroid(), 70000, 0, 180, 3000)
        setCirclePos(Asteroid(), 70000, 0, 240, 3000)
        setCirclePos(Asteroid(), 70000, 0, 300, 3000)
        setCirclePos(Asteroid(), 30000, 0, 0, 3000)
        setCirclePos(Asteroid(), 30000, 0, 60, 3000)
        setCirclePos(Asteroid(), 30000, 0, 120, 3000)
        setCirclePos(Asteroid(), 30000, 0, 180, 3000)
        setCirclePos(Asteroid(), 30000, 0, 240, 3000)
        setCirclePos(Asteroid(), 30000, 0, 300, 3000)

        Station:withStorageRooms(stationMine, {
            [products.ore] = 1000,
            [products.plutoniumOre] = 100,
        })

        local minerShip = MyCpuShip("Goods Freighter 1"):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(100):setRotationMaxSpeed(20)
        Util.spawnAtStation(stationMine, minerShip)

        Ship:withStorageRooms(minerShip, {
            [products.ore] = 250,
            [products.plutoniumOre] = 50,
        })
        Ship:orderMiner(minerShip, stationMine, function(asteroid, ship, station)
            local resources = {
                [products.ore] = math.random(10, 50)
            }
            if math.random(1, 5) == 1 then
                resources[products.plutoniumOre] = math.random(5, 10)
            end

            return resources
        end)

        removeGMFunction("Test Mining")
    end)

    addGMFunction("Test Patrol", function()
        local northPole = MySpaceStation("Small Station"):setFaction("Human Navy")
        local station1 = MySpaceStation("Medium Station"):setFaction("Human Navy")
        local station2 = MySpaceStation("Medium Station"):setFaction("Human Navy")
        local station3 = MySpaceStation("Medium Station"):setFaction("Human Navy")
        local station4 = MySpaceStation("Medium Station"):setFaction("Human Navy")

        setCirclePos(northPole, 0, -30000, 0, 20000)
        setCirclePos(station1, 0, -30000, 72, 20000)
        setCirclePos(station2, 0, -30000, 144, 20000)
        setCirclePos(station3, 0, -30000, 216, 20000)
        setCirclePos(station4, 0, -30000, 288, 20000)

        northPole:setDescription("A mysterious place")

        Cron.once(function()
            local rudolph = MyCpuShip("MU52 Hornet"):setRotation(0):setFaction("Human Navy")
            :setDescription("A ship with strange readings. It clearly does not satisfy any of the safety regulations put out by the Human Navy.")
            :setCallSign("XMAS17"):setCommsFunction(function()
                setCommsMessage("Ho! Ho! Ho!\n\nHave you been naughty or nice this year?")
                addCommsReply("Naughty", function()
                    setCommsMessage("I can't accept that. You have to be punished.")
                    Cron.once(function()
                        local x,y = player:getPosition()
                        setCirclePos(MyCpuShip("Atlantis X23"):setFaction("Ghosts"), x, y, math.random(0, 360), 5000):orderAttack(player)
                    end, 2)
                end)
                addCommsReply("Nice", function()
                    setCommsMessage("That's great. Keep it that way.")
                end)
            end):setWarpDrive(true)
            Ship:withCaptain(rudolph, Person.byName("Santa Claus"))

            Util.spawnAtStation(northPole, rudolph)

            Ship:patrol(rudolph, {
                {
                    target = station1,
                    onHeading = function()
                        ChitChat.say(rudolph, "Ho! Ho! Ho!")
                    end,
                    onArrival = function()
                        ChitChat.converse({
                            {rudolph, "Are you Timmy?"},
                            {"Timmy", "Mommy, who is that weirdo with the beard?"},
                            {"Mom", "It's Santa!"},
                            {rudolph, "Ho! Ho! Ho!"},
                            {"Timmy", "Why are you not coming through the chimney?"},
                            {rudolph, "Because you live on a Space Station and it has a central heating unit."},
                            {"Timmy", "But how does Rudolph breath in space?"},
                            {rudolph, "You ask way to many questions, Timmy."},

                        })
                    end,
                    delay = 30
                },{
                    target = station2,
                    onArrival = function()
                        ChitChat.converse({
                            {rudolph, "Marty, I brought you that Flux Capacitator, that you always wanted."},
                            {"Marty", "Yeah, you are like 60 years late, you dumbass."},
                        })
                    end,
                    delay = 30
                },{
                    target = station3,
                    onArrival = function()
                        ChitChat.converse({
                            {rudolph, "You have been very, very naughty."},
                            {"Kenny", "**unintelligable mumbling**"},
                            {station3, "*pew pew pew*"},
                            {"Kyle", "Oh my God! He killed Kenny!"},
                            {"Stan", "You bastard!"}
                        })
                    end,
                    delay = 30
                },{
                    target = northPole,
                    onHeading = function()
                        ChitChat.converse({
                            {rudolph, "That's all for this year."},
                            {rudolph, "Now for some Home brewed Egg Nogg at home."},
                        })
                    end,
                    onArrival = function()
                        ChitChat.say(rudolph, "Finally home.")
                        Cron.once(function() rudolph:destroy() end, 10)

                        northPole:setCommsFunction(function()
                            setCommsMessage("Have a Merry Christmas and a great year 2018, folks.")
                        end)
                        northPole:openCommsTo(player)
                    end,
                    delay = 999
                },
            })
        end, 100)

        Cron.regular("universe_travel", function()
            local source = Util.random({station1, station2, station3, station4})
            local destination = Util.random({station1, station2, station3, station4})

            if source ~= destination then
                narrative(source, destination)
            end
        end, 30)

        removeGMFunction("Test Patrol")
    end)
end

function update(delta)
    Cron.tick(delta)
end

-- boiler plate code – this will be improved
local narratives = {

    -- shipping cargo
    function(fromStation, toStation)
        local cargoList = {
            "birthday supplies",
            "wedding cake",
            "expensive art pieces",
            "fine meat",
            "newspapers",
            "latest fashion",
            "medicine",
            "robots",
        }

        local ship = MyCpuShip("Goods Freighter " .. math.random(1,5)):setWarpDrive(true):setFaction("Human Navy")
        Util.spawnAtStation(fromStation, ship)
        local cargo = Util.random(cargoList)

        Ship:patrol(ship, {
            {
                target = toStation,
                onHeading = function()
                    ship:setDescription("This ship brings " .. cargo .. " to " .. toStation:getCallSign() .. ".")
                end,
                onArrival = function()
                    ship:destroy()
                end
            }
        })
    end,
    -- transporting people
    function(fromStation, toStation)
        local passengerList = {
            {"party goers", "concert"},
            {"party goers", "night club"},
            {"students", "spring break celebration"},
            {"rich kids", "casino"},
            {"families", "vacation resort"},
            {"families", "christmas celebration"},
            {"laborers", "construction side"},
            {"politicians", "debate"},
        }

        local i = math.random(1,5)
        local ship = MyCpuShip("Personnel Freighter " .. i):setWarpDrive(true):setFaction("Human Navy")
        Util.spawnAtStation(fromStation, ship)
        local passengers = Util.random(passengerList)
        local number = math.random(1, 5) * (i-1) + math.random(1,5)

        Ship:patrol(ship, {
            {
                target = toStation,
                onHeading = function()
                    ship:setDescription(
                        "There are " ..
                                number ..
                                " " ..
                                passengers[1] ..
                                " on board going to a " ..
                                passengers[2] ..
                                " on " ..
                                toStation:getCallSign() ..
                                ".")
                end,
                onArrival = function()
                    ship:destroy()
                end
            }
        })
    end,
}

function narrative(fromStation, toStation)
    return Util.random(narratives)(fromStation, toStation)
end