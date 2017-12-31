-- Name: Hello World
-- Description: Testing stuff
-- Type: Mission

require "src/lively_epsilon/init.lua"

function MySpaceStation(template)
    local station = Station:enrich(SpaceStation():setTemplate(template))
    Station:withComms(station)
    station:setHailText("Hello World")
    return station
end

function init()

    player = Player:enrich(
        PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(200):setImpulseMaxSpeed(250):setRotationMaxSpeed(50):setWarpDrive(true):setJumpDrive(true)
    )

    addGMFunction("Test Missions", function()
        local station1 = MySpaceStation("Small Station"):setPosition(8000, 8000):setFaction("Human Navy"):setRotation(random(0, 360)):setDescription("A herring factory")
        local station2 = MySpaceStation("Medium Station"):setPosition(-8000, 8000):setFaction("Human Navy"):setRotation(random(0, 360))
        local station3 = MySpaceStation("Large Station"):setPosition(8000, -8000):setFaction("Human Navy"):setRotation(random(0, 360))
        local station4 = MySpaceStation("Huge Station"):setPosition(-8000, -8000):setFaction("Human Navy"):setRotation(random(0, 360))

        Station:withMissions(station1)
        station1:addComms("Mission Board", Comms.defaultMissionBoard)
        station1:addMission(MissionGenerator.transport(station1, station2))
        station1:addMission(MissionGenerator.transport(station1, station3))
        station1:addMission(MissionGenerator.transport(station1, station4))

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

        local ship = Ship:enrich(
            CpuShip():setTemplate("Goods Freighter 1"):setPosition(11000, 0):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(250):setRotationMaxSpeed(50)
        )
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

        local minerShip = Ship:enrich(
            CpuShip():setTemplate("Goods Freighter 1"):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(100):setRotationMaxSpeed(20)
        )
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
            local rudolph = Ship:enrich(
                CpuShip():setTemplate("MU52 Hornet"):setRotation(0):setFaction("Human Navy")
                :setDescription("A ship with strange readings. It clearly does not satisfy any of the safety regulations put out by the Human Navy.")
            ):setCallSign("XMAS17"):setCommsFunction(function()
                setCommsMessage("Ho! Ho! Ho!\n\nHave you been naughty or nice this year?")
                addCommsReply("Naughty", function()
                    setCommsMessage("I can't accept that. You have to be punished.")
                    Cron.once(function()
                        local x,y = player:getPosition()
                        setCirclePos(CpuShip():setTemplate("Atlantis X23"):setFaction("Ghosts"), x, y, math.random(0, 360), 5000):orderAttack(player)
                    end, 2)
                end)
                addCommsReply("Nice", function()
                    setCommsMessage("That's great. Keep it that way.")
                end)
            end):setWarpDrive(true)

            rudolph.captain.firstName = "Santa"
            rudolph.captain.lastName = "Claus"

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

        local ship = Ship:enrich(CpuShip():setTemplate("Goods Freighter " .. math.random(1,5)):setWarpDrive(true):setFaction("Human Navy"))
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
        local ship = Ship:enrich(CpuShip():setTemplate("Personnel Freighter " .. i):setWarpDrive(true):setFaction("Human Navy"))
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