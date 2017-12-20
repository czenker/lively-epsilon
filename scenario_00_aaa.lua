-- Name: Hello World
-- Description: Testing stuff
-- Type: Mission

require "src/lively_epsilon/init.lua"

function init()

    player = Player:enrich(
        PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(200):setImpulseMaxSpeed(250):setRotationMaxSpeed(50):setWarpDrive(true):setJumpDrive(true)
    )

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

end

function update(delta)
    Cron.tick(delta)
end
