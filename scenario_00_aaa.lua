-- Name: Hello World
-- Description: Testing stuff
-- Type: Mission

require "src/lively_epsilon/init.lua"
require "resources/personNames.lua"
require "resources/products.lua"

function MySpaceStation(station)
    station = station or SpaceStation()
    Station:withComms(station)
    station:setHailText("Hello World")
    return station
end

function MyCpuShip(ship)
    ship = ship or CpuShip()

    Ship:withCaptain(ship, Person:newHuman())

    Ship:withComms(ship)
    ship:setHailText(function(self, player)
        return "Hello " .. player:getCallSign() .. ".\n\nThis is Captain " .. self:getCrewAtPosition("captain"):getFormalName() .. " of " .. self:getCallSign() .. ". How can I help you?"
    end)

    return ship
end

function init()

    local player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(200):setImpulseMaxSpeed(250):setRotationMaxSpeed(50):setWarpDrive(true):setJumpDrive(true)

    addGMFunction("Test Missions", function()
        Player:withMissionTracker(player)
        Player:withMissionDisplay(player)

        local station1 = MySpaceStation():setTemplate("Large Station"):setPosition(8000, 8000):setFaction("Human Navy"):setRotation(random(0, 360)):setDescription("A herring factory")
        local station2 = MySpaceStation():setTemplate("Medium Station"):setPosition(-8000, 8000):setFaction("Human Navy"):setRotation(random(0, 360))

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
        station1:addComms(Comms.defaultMissionBoard)
        station1:addMission(herringMission)
        station1:addMission(destructionMission)

        removeGMFunction("Test Missions")
    end)


    addGMFunction("Test Production", function()

        local stationSolar = MySpaceStation():setTemplate("Medium Station"):setPosition(-5000, 10000):setFaction("Human Navy")
        local stationFabricate = MySpaceStation():setTemplate("Medium Station"):setPosition(0, 10000):setFaction("Human Navy")
        local stationConsume = MySpaceStation():setTemplate("Medium Station"):setPosition(5000, 10000):setFaction("Human Navy")
        stationSolar:addComms(Comms.defaultMerchant)
        stationFabricate:addComms(Comms.defaultMerchant)
        stationConsume:addComms(Comms.defaultMerchant)

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

        local ship = MyCpuShip():setTemplate("Goods Freighter 1"):setPosition(11000, 0):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(250):setRotationMaxSpeed(50)
        Ship:withStorageRooms(ship, {
            [products.power] = 1000,
        })
        Ship:orderBuyer(ship, stationFabricate, products.power)

        removeGMFunction("Test Production")
    end)

    addGMFunction("Test Mining", function()
        local stationMine = MySpaceStation():setTemplate("Medium Station"):setPosition(50000, 0):setFaction("Human Navy")

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

        local minerShip = MyCpuShip():setTemplate("Goods Freighter 1"):setRotation(0):setFaction("Human Navy"):setImpulseMaxSpeed(100):setRotationMaxSpeed(20)
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
        local station1 = MySpaceStation():setTemplate("Medium Station"):setFaction("Human Navy")
        local station2 = MySpaceStation():setTemplate("Medium Station"):setFaction("Human Navy")
        local station3 = MySpaceStation():setTemplate("Medium Station"):setFaction("Human Navy")
        local station4 = MySpaceStation():setTemplate("Medium Station"):setFaction("Human Navy")

        setCirclePos(station1, 0, -30000, 30, 20000)
        setCirclePos(station2, 0, -30000, 120, 20000)
        setCirclePos(station3, 0, -30000, 210, 20000)
        setCirclePos(station4, 0, -30000, 300, 20000)

        MyNarrative:addStation(station1)
        MyNarrative:addStation(station2)
        MyNarrative:addStation(station3)
        MyNarrative:addStation(station4)

        Cron.regular("universe_travel", function()
            local n = MyNarrative:findOne()
            if not isNil(n) then Narrative:run(n) end
        end, 30)

        removeGMFunction("Test Patrol")
    end)
end

function update(delta)
    Cron.tick(delta)
end

MyNarrative = Narrative:newRepository()

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

local passengerList = {
    { "party goers", "concert" },
    { "party goers", "night club" },
    { "students", "spring break celebration" },
    { "rich kids", "casino" },
    { "families", "vacation resort" },
    { "families", "christmas celebration" },
    { "laborers", "construction side" },
    { "politicians", "debate" },
}

MyNarrative:addNarrative({
    name = "Shipping cargo",
    onCreation = function(ship, from, to)
        local cargo = Util.random(cargoList)

        MyCpuShip(ship)
        ship:setTemplate("Goods Freighter " .. math.random(1, 5)):setWarpDrive(true)
        ship:setFaction(from:getFaction())
        ship:setDescription("This ship brings " .. cargo .. " to " .. to:getCallSign() .. ".")
    end
})

MyNarrative:addNarrative({
    name = "Transporting people",
    onCreation = function(ship, from, to)
        local i = math.random(1, 5)
        local number = math.random(1, 5) * (i - 1) + math.random(1, 5)
        local passengers = Util.random(passengerList)

        MyCpuShip(ship)
        ship:setTemplate("Goods Freighter " .. i):setWarpDrive(true)
        ship:setFaction(from:getFaction())
        ship:setDescription("There are " ..
                number ..
                " " ..
                passengers[1] ..
                " on board going to a " ..
                passengers[2] ..
                " on " ..
                to:getCallSign() ..
                ".")
    end
})
