-- Name: Hello World
-- Description: Testing stuff
-- Type: Mission

function init()
    --player2 = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(0)
	Nebula():setPosition(-5000, 0)
    --Artifact():setPosition(1000, 9000):setModel("small_frigate_1"):setDescription("An old space derelict.")
    --Artifact():setPosition(9000, 2000):setModel("small_frigate_1"):setDescription("A wrecked ship.")
    --Artifact():setPosition(3000, 4000):setModel("small_frigate_1"):setDescription("Tons of rotting plasteel.")
    --addGMFunction("move 1 to 2", function() player1:transferPlayersToShip(player2) end)
    --addGMFunction("move 2 to 1", function() player2:transferPlayersToShip(player1) end)
--    CpuShip():setTemplate("Adder MK5"):setPosition(0, 0):setRotation(0):setFaction("Human Navy")
    --CpuShip():setTemplate("Piranha F12"):setPosition(2000, 0):setRotation(-90):setFaction("Kraylor")
--    planet1 = Planet():setPosition(5000, 5000):setPlanetRadius(3000):setDistanceFromMovementPlane(-2000):setPlanetSurfaceTexture("planets/planet-1.png"):setPlanetCloudTexture("planets/clouds-1.png"):setPlanetAtmosphereTexture("planets/atmosphere.png"):setPlanetAtmosphereColor(0.2,0.2,1.0)
--    moon1 = Planet():setPosition(5000, 0):setPlanetRadius(1000):setDistanceFromMovementPlane(-2000):setPlanetSurfaceTexture("planets/moon-1.png"):setAxialRotationTime(20.0)
--    sun1 = Planet():setPosition(5000, 15000):setPlanetRadius(1000):setDistanceFromMovementPlane(-2000):setPlanetAtmosphereTexture("planets/star-1.png"):setPlanetAtmosphereColor(1.0,1.0,1.0)
--    planet1:setOrbit(sun1, 40)
--    moon1:setOrbit(planet1, 20.0)

    require "src/lively_epsilon/init.lua"

    player = Player:enrich(
        PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(200):setImpulseMaxSpeed(250):setRotationMaxSpeed(50):setWarpDrive(true):setJumpDrive(true)
    )

    require "resources/products.lua"

--    AlTrader.addStation(station1)
--    AlTrader.addStation(station2)
--    AlTrader.addStation(station3)
--    AlTrader.addStation(station4)
--
--    AlTrader.addTrader()
--    AlTrader.addTrader()
--    AlTrader.addTrader()

--    ship = Ship:enrich(
--        CpuShip():setTemplate("Adder MK5"):setPosition(1000, 0):setRotation(0):setFaction("Human Navy")
--    )
--    ship2 = Ship:enrich(
--        CpuShip():setTemplate("Adder MK5"):setPosition(2000, 0):setRotation(0):setFaction("Human Navy")
--    )



    addGMFunction("Test Missions", function()
        local station1 = Station:enrich(SpaceStation():setPosition(8000, 8000):setTemplate('Small Station'):setFaction("Human Navy"):setRotation(random(0, 360)):setDescription("Eine Erzbergbaustation"))
        local station2 = Station:enrich(SpaceStation():setPosition(-8000, 8000):setTemplate('Medium Station'):setFaction("Human Navy"):setRotation(random(0, 360)))
        local station3 = Station:enrich(SpaceStation():setPosition(8000, -8000):setTemplate('Large Station'):setFaction("Human Navy"):setRotation(random(0, 360)))
        local station4 = Station:enrich(SpaceStation():setPosition(-8000, -8000):setTemplate('Huge Station'):setFaction("Human Navy"):setRotation(random(0, 360)))

        Station:withMissions(station1)
        station1:addMission(MissionGenerator.transport(station1, station2))
        station1:addMission(MissionGenerator.transport(station1, station3))
        station1:addMission(MissionGenerator.transport(station1, station4))

        removeGMFunction("Test Missions")
    end)


    addGMFunction("Test Production", function()

        local stationSolar = Station:enrich(
            SpaceStation():setPosition(-5000, 10000):setTemplate('Medium Station'):setFaction("Human Navy")
        )
        local stationFabricate = Station:enrich(
            SpaceStation():setPosition(0, 10000):setTemplate('Medium Station'):setFaction("Human Navy")
        )
        local stationConsume = Station:enrich(
            SpaceStation():setPosition(5000, 10000):setTemplate('Medium Station'):setFaction("Human Navy")
        )

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
        local stationMine = Station:enrich(
            SpaceStation():setPosition(50000, 0):setTemplate('Medium Station'):setFaction("Human Navy")
        )

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
--        local station = Station:enrich(SpaceStation():setPosition(40000, 5000):setTemplate('Medium Station'):setFaction("Human Navy"):setRotation(random(0, 360)))

        local function onHeading(ship)
            ChitChat.say(ship, "Let's go")
        end
        local function onArrival(ship)
            ChitChat.say(ship, "Arrived")
        end

        for i=3,13,1 do
            Ship:patrol(CpuShip():setTemplate("Adder MK5"):setPosition(0, i * 5000):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(250):setRotationMaxSpeed(50), {
                {
                    target = {-5000, i * 5000 },
                    onHeading = onHeading,
                    onArrival = onArrival,
                    delay = i - 3
                },
                {
                    target = {5000, i * 5000 },
                    onHeading = onHeading,
                    onArrival = onArrival,
                    delay = i - 3
                },
            })
        end

        removeGMFunction("Test Patrol")
    end)

    addGMFunction("Test AlRoute", function()

        local station1 = Station:enrich(SpaceStation():setPosition(20000, 5000):setTemplate('Medium Station'):setFaction("Human Navy"):setRotation(random(0, 360)))
        local station2 = Station:enrich(SpaceStation():setPosition(30000, 5000):setTemplate('Medium Station'):setFaction("Human Navy"):setRotation(random(0, 360)))
        local station3 = Station:enrich(SpaceStation():setPosition(20000, 15000):setTemplate('Medium Station'):setFaction("Human Navy"):setRotation(random(0, 360)))
        local station4 = Station:enrich(SpaceStation():setPosition(30000, 15000):setTemplate('Medium Station'):setFaction("Human Navy"):setRotation(random(0, 360)))


        local fooShip = Ship:enrich(
            CpuShip():setTemplate("Adder MK5"):setPosition(1000, 0):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(250):setRotationMaxSpeed(50)
        )
        Util.spawnAtStation(station1, fooShip)

        AlRoute.add({
            ship = fooShip,
            onBeginning = function()
                ChitChat.say(fooShip, "God, what am I hungry for some cheese.")
            end,
            waypoints = {
                {
                    target = station1,
                    onDocking = function()
                        ChitChat.converse({
                            {fooShip, "Hello " .. station1:getCallSign() .. ". I'd like to buy some cheese, please."},
                            {station1, "We don't have any cheese - maybe you can try Station " .. station2:getCallSign() .. "."},
                            {fooShip, "Ok, I'll give that one a try."}
                        })
                    end,
                    dockingTime = 20
                },
                {
                    target = station2,
                    onHeading = function()
                        ChitChat.say(fooShip, "Let's go to " .. station2:getCallSign())
                    end,
                    onApproaching = function()
                        ChitChat.converse({
                            {fooShip, "Requesting the right to dock."},
                            {station2, "Granted"}
                        })
                    end,
                    onDocking = function()
                        ChitChat.converse({
                            {fooShip, "Hello " .. station2:getCallSign() ..". I'd like to buy some cheese, please."},
                            {station2, "Fortunately we have some. Here, take it all."}
                        })
                    end,
                    dockingTime = 10
                },
            },
            onFinish = function()
                ChitChat.say(fooShip, "And that is all for the day.")
                fooShip:destroy()
            end
        })

        local fooShip = Ship:enrich(
            CpuShip():setTemplate("Adder MK5"):setPosition(1000, 0):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(250):setRotationMaxSpeed(50)
        )
        Util.spawnAtStation(station2, fooShip)

        AlRoute.loop({
            ship = fooShip,
            waypoints = {
                {
                    target = station2,
                    onDocking = function()
                        ChitChat.converse({
                            {fooShip, "Hello, I'm looking for Permit A 38. I heard I can get it from you."},
                            {station2, "Yes, you can. But only if you have circular B 65."},
                            {fooShip, "Oh! Where can I get one of those?"},
                            {station2, "Try " .. station3:getCallSign() .. "."},
                        })
                    end,
                    dockingTime = 30
                },
                {
                    target = station3,
                    onDocking = function()
                        ChitChat.converse({
                            {fooShip, "Can I have a Circular B 65, please?"},
                            {station3, "Do you have a permit A 39."},
                            {fooShip, "Hell no. Do I need that?"},
                            {station3, "Yes you do. Ask " .. station4:getCallSign() .. " to get you one."},
                        })
                    end,
                    dockingTime = 30
                },
                {
                    target = station4,
                    onDocking = function()
                        ChitChat.converse({
                            {fooShip, "I'm on the look for a permit A39."},
                            {station4, "Ah, I got one right here. I just need you to show me your Permit A 38."},
                            {fooShip, "Ok, but where do I get that?"},
                            {station4, "You could ask " .. station2:getCallSign() .. ". They should be able to help you."},
                        })
                    end,
                    dockingTime = 30
                },
            },
            onDestruction = function()
                ChitChat.say(fooShip, "Finally I got free from this curse!")
            end
        })

        removeGMFunction("Test AlRoute")
    end)

    addGMFunction("clickme", function()
        player:addCustomInfo("helms", "info", "Hello Relay")
        player:addCustomButton("helms", "button", "Can't touch this", function()
            print("Button was touched")
        end)
        player:addCustomMessage("helms", "message", "This is a message")
        player:addCustomMessageWithCallback("helms", "cb", "This is a message with a callback", function()
            print("Message callback triggered")
        end)
    end)


end

function update(delta)
    Cron.tick(delta)
end
