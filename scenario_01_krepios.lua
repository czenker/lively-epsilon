-- Name: Krepios
-- Description: The player crew finds itself in a mining colony far away from any civilization.
--- Recommended to be played with 20u scanner range.
-- Type: Mission

-- ----------------------------
--
-- GM: Configure your game here
--
-- ----------------------------

require "src/lively_epsilon/init.lua"

-- decrease if your framerate is bad
-- increase if you want a more dense looking asteroid field
-- has no impact on gameplay
local visualDensity = 20
-- the commander that gave the crew the task to fly to the SMC main station
local highCommand = Person.byName("Lieutenant John Doe")
-- the name of the commander of the SMC main station
local commander = Person.byName("Wright Hartman")
local playerShipName = "LC Libell"


-- includes
require "resources/personNames.lua"
require "01_krepios/products.lua"
require "resources/merchants.lua"
require "01_krepios/spaceObjects.lua"
require "01_krepios/intro.lua"
require "01_krepios/side_missions.lua"
require "01_krepios/upgrades.lua"

local function mineAsteroid(asteroid, ship, station)
    local resources = {
        [products.ore] = math.random(0, 10)
    }
    if math.random(1, 5) == 1 then
        resources[products.plutoniumOre] = math.random(1, 2)
    end

    return resources
end

local function makeItAMine(station)
    Station:withStorageRooms(station, {
        [products.ore] = 400,
        [products.plutoniumOre] = 40,
        [products.miningMachinery] = 100,
        [products.hvli] = 8,
        [products.homing] = 8,
        [products.mine] = 4,
    })
    Station:withMerchant(station, {
        [products.ore] = { sellingPrice = sellingPrice(products.ore), sellingLimit = 60 },
        [products.plutoniumOre] = { sellingPrice = sellingPrice(products.plutoniumOre) },
        [products.miningMachinery] = { buyingPrice = buyingPrice(products.miningMachinery) },
        [products.hvli] = { sellingPrice = sellingPrice(products.hvli)},
        [products.homing] = { sellingPrice = sellingPrice(products.homing) },
        [products.mine] = { sellingPrice = sellingPrice(products.mine) },
    })
    station:modifyProductStorage(products.ore, math.random(100, 200))
    station:modifyProductStorage(products.plutoniumOre, math.random(10, 20))
    station:modifyProductStorage(products.miningMachinery, math.random(20, 40))
    station:modifyProductStorage(products.hvli, math.random(0, 4))
    station:modifyProductStorage(products.homing, math.random(0, 4))
    station:modifyProductStorage(products.mine, math.random(0, 2))

    Station:withProduction(station, {
        {
            productionTime = math.random(162, 192),
            consumes = {
                { product = products.ore, amount = 6 }
            },
            produces = {
                { product = products.homing, amount = 2 }
            }
        },{
            productionTime = math.random(108, 132),
            consumes = {
                { product = products.ore, amount = 6 }
            },
            produces = {
                { product = products.hvli, amount = 2 }
            }
        },{
            productionTime = math.random(162, 192),
            consumes = {
                { product = products.ore, amount = 6 }
            },
            produces = {
                { product = products.mine, amount = 1 }
            }
        },{
            productionTime = math.random(81, 99),
            consumes = {
                { product = products.miningMachinery, amount = 1 }
            },
        },
    })

    station:addTag("mining")

    local function spawnMiner()
        local miner = MyCpuShip(CpuShip():setTemplate("MT52 Hornet"):setFaction(station:getFaction()))
        miner:setAI("default")

        Util.spawnAtStation(station, miner)

        Ship:withStorageRooms(miner, {
            [products.ore] = 60,
            [products.plutoniumOre] = 5,
        })
        Ship:orderMiner(miner, station, mineAsteroid, {
            timeToUnload = math.random(15, 30),
            timeToMine = math.random(15, 30),
            timeToGoHome = math.random(450, 900),
            maxDistanceFromHome = math.random(20000, 30000),
            maxDistanceToNext = math.random(5000, 15000),
        })

        return miner
    end

    local miner1 = spawnMiner()
    local miner2 = spawnMiner()
    local cronId = "mine_" .. station:getCallSign()

    Cron.regular(cronId, function()
        if not station:isValid() then
            Cron.abort(cronId)
        else
            if not isEeShip(miner1) or not miner1:isValid() then
                miner1 = spawnMiner()
            elseif not isEeShip(miner2) or not miner2:isValid() then
                miner2 = spawnMiner()
            end
        end
    end, math.random(55, 64) + math.random())

    return station
end

local function makeItAMainStation(station, wormHole)
    Station:withStorageRooms(station, {
        [products.ore] = 400,
        [products.plutoniumOre] = 40,
        [products.miningMachinery] = 100,
        [products.hvli] = 20,
        [products.homing] = 20,
        [products.mine] = 10,
        [products.emp] = 10,
        [products.nuke] = 5,
    })
    station:modifyProductStorage(products.miningMachinery, math.random(40, 80))
    station:modifyProductStorage(products.ore, 400)
    station:modifyProductStorage(products.hvli, math.random(0, 4))
    station:modifyProductStorage(products.homing, math.random(0, 4))
    station:modifyProductStorage(products.mine, math.random(0, 2))
    station:modifyProductStorage(products.emp, math.random(0, 2))
    station:modifyProductStorage(products.nuke, math.random(0, 1))
    Station:withMerchant(station, {
        [products.ore] = { buyingPrice = buyingPrice(products.ore) },
        [products.plutoniumOre] = { buyingPrice = buyingPrice(products.plutoniumOre) },
        [products.miningMachinery] = { sellingPrice = sellingPrice(products.miningMachinery) },
        [products.hvli] = { sellingPrice = sellingPrice(products.hvli)},
        [products.homing] = { sellingPrice = sellingPrice(products.homing) },
        [products.mine] = { sellingPrice = sellingPrice(products.mine) },
        [products.emp] = { sellingPrice = sellingPrice(products.emp) },
        [products.nuke] = { sellingPrice = sellingPrice(products.nuke) },
    })

    Station:withProduction(station, {
        {
            productionTime = math.random(80, 100),
            consumes = {
                { product = products.ore, amount = 6 }
            },
            produces = {
                { product = products.homing, amount = 2 }
            }
        },{
            productionTime = math.random(55, 65),
            consumes = {
                { product = products.ore, amount = 6 }
            },
            produces = {
                { product = products.hvli, amount = 2 }
            }
        },{
            productionTime = math.random(80, 100),
            consumes = {
                { product = products.ore, amount = 6 }
            },
            produces = {
                { product = products.mine, amount = 1 }
            }
        },{
            productionTime = math.random(162, 198),
            consumes = {
                { product = products.ore, amount = 4 },
                { product = products.plutoniumOre, amount = 1 },
            },
            produces = {
                { product = products.emp, amount = 1 }
            }
        },{
            productionTime = math.random(270, 330),
            consumes = {
                { product = products.ore, amount = 6 },
                { product = products.plutoniumOre, amount = 2 },
            },
            produces = {
                { product = products.nuke, amount = 1 }
            }
        },{
            productionTime = math.random(108, 132),
            consumes = {
                { product = products.ore, amount = 20 },
            },
            produces = {
                { product = products.miningMachinery, amount = 2 }
            }
        },
    })

    station:addTag("residual")

    local function spawnBuyer(product)
        local size = math.random(1, 3)
        local ship = MyCpuShip(CpuShip():setTemplate("Goods Freighter " .. size):setFaction(station:getFaction()))

        Util.spawnAtStation(station, ship)

        Ship:withStorageRooms(ship, {
            [product] = math.floor(100 * size / product:getSize()),
        })
        Ship:orderBuyer(ship, station, product, {
            maxDistanceFromHome = 30000,
        })

        return ship
    end

    local buyerOre = spawnBuyer(products.ore)
    local buyerPlutonium = spawnBuyer(products.plutoniumOre)

    local cronId = "hq" .. station:getCallSign()
    Cron.regular(cronId, function()
        if not station:isValid() then
            Cron.abort(cronId)
        else
            if not isEeShip(buyerOre) or not buyerOre:isValid() then
                buyerOre = spawnBuyer(products.ore)
            elseif not isEeShip(buyerPlutonium) or not buyerPlutonium:isValid() then
                buyerPlutonium = spawnBuyer(products.plutoniumOre)
            end
        end
    end, math.random(55, 64) + math.random())

    return station
end

local function eraseAsteroidsAround(x, y, radius)
    radius = radius or 5000
    for _,obj in pairs(getObjectsInRadius(x,y,radius)) do
        if isEeAsteroid(obj) then obj:destroy() end
    end
end

function init()
    local planet = Planet():setPosition(0, 0):setPlanetRadius(5000):setPlanetSurfaceTexture("planets/planet-2.png"):setAxialRotationTime(1000)

    -- this is the basic spiral
    local distancePerGrad = 180000 / 360
    local avgAngle = math.random(0,360)
    local minAngle = avgAngle - 45
    local maxAngle = minAngle + 45

    local maxDistance = 270000

    local numberOfAsteroids = 250
    local foo = maxDistance * maxDistance

    local step = foo / numberOfAsteroids

    while foo > 0 do
        local distance = math.sqrt(foo)
        local angle = math.random(minAngle, maxAngle) + distance / distancePerGrad
        local x,y = vectorFromAngle(angle, distance)
        Asteroid():setPosition(x, y)

        local angle = math.random(minAngle, maxAngle) + distance / distancePerGrad
        local x,y = vectorFromAngle(angle, distance)
        VisualAsteroid():setPosition(x, y)

        foo = foo - step
    end

    -- make the asteroid field look more dense in the AO of the player
    for angle=420,480 do
        local minDistance = distancePerGrad * angle
        local maxDistance = distancePerGrad * (angle+45)
        local x,y = vectorFromAngle(maxAngle+angle, math.random(minDistance, maxDistance))
        Asteroid():setPosition(x, y)

        local x,y = vectorFromAngle(maxAngle+angle, math.random(minDistance, maxDistance))
        Asteroid():setPosition(x, y)

        for i=1,visualDensity do
            local x,y = vectorFromAngle(maxAngle+angle+math.random()-0.5, math.random(minDistance, maxDistance))
            VisualAsteroid():setPosition(x, y)
        end
    end

    -- the WormHole that connects Krepios to the other systems
    local holeX, holeY = vectorFromAngle(maxAngle + math.random(240, 300), distancePerGrad*120)
    local wormHole = WormHole():setPosition(holeX, holeY):setTargetPosition(-999999, -999999)

    -- let's make some stations
    local hqX, hqY = vectorFromAngle(maxAngle + 450, distancePerGrad*450 - 2000)
    eraseAsteroidsAround(hqX, hqY)
    local hq = MySpaceStation(SpaceStation():setTemplate("Huge Station"):setFaction("Human Navy")):setPosition(hqX, hqY):
        setCallSign("SMC HQ"):setDescription("Die einzige Station im äußeren im äußeren Meteoritenbereich, den man mit einem zugedrückten Auge als \"zivilisiert\" bezeichnen kann. Familien von Bergarbeitern geniesen hier den relativen Luxus, den Casions, Einkaufszentren und unzählige Bars bieten.")

    makeItAMainStation(hq, wormHole)

--    local hqDefenderFlagship = MyCpuShip(CpuShip():setTemplate("Phobos T3"):setFaction("Human Navy"))
--    Util.spawnAtStation(hq, hqDefenderFlagship)
--    hqDefenderFlagship:orderDefendTarget(hq)
--    local hqDefenderWingman1 = MyCpuShip(CpuShip():setTemplate("Adder MK5"):setFaction("Human Navy"))
--    Util.spawnAtStation(hq, hqDefenderWingman1)
--    hqDefenderWingman1:orderFlyFormation(hqDefenderFlagship, 500, -500)
--    local hqDefenderWingman2 = MyCpuShip(CpuShip():setTemplate("Adder MK5"):setFaction("Human Navy"))
--    Util.spawnAtStation(hq, hqDefenderWingman2)
--    hqDefenderWingman2:orderFlyFormation(hqDefenderFlagship, 500, 500)

    local player = MyPlayer(PlayerSpaceship():setFaction("Human Navy"):setTemplate("Flavia P.Falcon"):setCallSign(playerShipName)):setWarpDrive(false)
    setCirclePos(player, hqX, hqY, maxAngle + 270, 2000)
    player:setRotation(maxAngle + 450)
    player:commandTargetRotation(maxAngle + 450)
    player:setRepairCrewCount(4)
    player:setImpulseMaxSpeed(60)
    player:setRotationMaxSpeed(10)
    player:setCombatManeuver(0, 0)
    player:setWarpDrive(false)
    player:setJumpDrive(false)
    player:setWeaponStorageMax("hvli", 2)
    player:setWeaponStorageMax("homing", 2)
    player:setWeaponStorageMax("mine", 0)
    player:setWeaponStorageMax("nuke", 0)
    player:setWeaponStorageMax("emp", 0)
    for _,weapon in pairs({"hvli", "homing", "mine", "nuke", "emp"}) do
        player:setWeaponStorage(weapon, player:getWeaponStorageMax(weapon))
    end
    player:setMaxEnergy(500)

    player:setReputationPoints(2000)

    local ms1X, ms1Y = vectorFromAngle(maxAngle + 450 - 80 + math.random(0, 30), math.random(16000, 30000))
    ms1X, ms1Y = ms1X + hqX, ms1Y + hqY
    eraseAsteroidsAround(ms1X, ms1Y)
    local miningStation1 = MySpaceStation(SpaceStation():setTemplate("Medium Station"):setFaction("Human Navy")):setPosition(ms1X, ms1Y):setCallSign("SMC Alpha")
    makeItAMine(miningStation1)

    local ms2X, ms2Y = vectorFromAngle(maxAngle + 450 - 15 + math.random(0, 30), math.random(12000, 20000))
    ms2X, ms2Y = ms2X + hqX, ms2Y + hqY
    eraseAsteroidsAround(ms2X, ms2Y)
    local miningStation2 = MySpaceStation(SpaceStation():setTemplate("Medium Station"):setFaction("Human Navy")):setPosition(ms2X, ms2Y):setCallSign("MC Beta")
    makeItAMine(miningStation2)

    local ms3X, ms3Y = vectorFromAngle(maxAngle + 450 + 50 + math.random(0, 30), math.random(16000, 30000))
    ms3X, ms3Y = ms3X + hqX, ms3Y + hqY
    eraseAsteroidsAround(ms3X, ms3Y)
    local miningStation3 = MySpaceStation(SpaceStation():setTemplate("Medium Station"):setFaction("Human Navy")):setPosition(ms3X, ms3Y):setCallSign("MC Gamma")
    makeItAMine(miningStation3)

    local missionGenerator = My.MissionGenerator({hq, miningStation1, miningStation2, miningStation3}, player)

    -- --------------------------
    --
    -- Offer missions on stations
    --
    -- --------------------------

    Station:withMissionBroker(hq)
    Station:withMissionBroker(miningStation1)
    Station:withMissionBroker(miningStation2)
    Station:withMissionBroker(miningStation3)

    -- the numbers of missions to add to the station in the next tick
    local missionsNextTick = {
        [hq] = 3,
        [miningStation1] = 3,
        [miningStation2] = 3,
        [miningStation3] = 3,
    }

    Cron.regular("mission_refill", function()
        for station, numberMissions in pairs(missionsNextTick) do
            if station:isValid() and Station:hasMissionBroker(station) then
                if numberMissions > 0 then
                    logDebug(string.format("Refilling %d missions for %s", numberMissions, station:getCallSign()))
                    -- refill new missions
                    local nrFightingMissions = 0
                    local nrTransportMissions = 0
                    for _, mission in pairs(station:getMissions()) do
                        if mission:hasTag("transport") then
                            nrTransportMissions = nrTransportMissions + 1
                        elseif mission:hasTag("fighting") then
                            nrFightingMissions = nrFightingMissions + 1
                        end
                    end
                    for i=1,numberMissions do
                        if nrFightingMissions < nrTransportMissions or (nrFightingMissions == nrTransportMissions and math.random(0,1) == 0) then
                            nrFightingMissions = nrFightingMissions + 1
                            station:addMission(missionGenerator.randomFightingMission(station))
                        else
                            nrTransportMissions = nrTransportMissions + 1
                            station:addMission(missionGenerator.randomTransportMission(station))
                        end
                    end
                end

                -- count how many missions to add in the next tick
                missionsNextTick[station] = math.max(0, 3 - Util.size(station:getMissions()))
            end
        end
    end, 180)

    -- --------------------------
    --
    -- offer upgrades on stations
    --
    -- --------------------------

    local upgrades = Util.randomSort({
        My.Upgrades.speed1,
        My.Upgrades.speed2,
        My.Upgrades.speed3,
        My.Upgrades.rotation1,
        My.Upgrades.rotation2,
        My.Upgrades.storage1,
        My.Upgrades.storage2,
        My.Upgrades.combatManeuver,
        My.Upgrades.hvli1,
        My.Upgrades.hvli2,
        My.Upgrades.homing1,
        My.Upgrades.homing2,
        My.Upgrades.mine1,
        My.Upgrades.mine2,
        My.Upgrades.mine3,
        My.Upgrades.emp1,
        My.Upgrades.emp2,
        My.Upgrades.emp3,
        My.Upgrades.nuke1,
        My.Upgrades.nuke2,
        My.Upgrades.energy1,
        My.Upgrades.energy2,
        My.Upgrades.energy3,
    })

    for i, upgrade in pairs(upgrades) do
        if i%4 == 0 then
            hq:addUpgrade(upgrade)
        elseif i%4 == 1 then
            miningStation1:addUpgrade(upgrade)
        elseif i%4 == 2 then
            miningStation2:addUpgrade(upgrade)
        else
            miningStation3:addUpgrade(upgrade)
        end
    end

    hq:addUpgrade(My.Upgrades.warpDrive)
    hq:addUpgrade(My.Upgrades.jumpDrive)

    -- give the player some missions to start with
    local missionMs1 = Missions:visit(miningStation1, {onSuccess = function() player:addReputationPoints(20) end})
    missionMs1:setPlayer(player)
    Mission:withBroker(missionMs1, "Besuchen Sie " .. miningStation1:getCallSign(), {missionBroker = hq})
    missionMs1:accept(); missionMs1:start()
    player:addMission(missionMs1)
    local missionMs2 = Missions:visit(miningStation2, {onSuccess = function() player:addReputationPoints(30) end})
    missionMs2:setPlayer(player)
    Mission:withBroker(missionMs2, "Finden und besuchen Sie " .. miningStation2:getCallSign(), {missionBroker = hq})
    missionMs2:accept(); missionMs2:start()
    player:addMission(missionMs2)
    local missionMs3 = Missions:visit(miningStation3, {onSuccess = function() player:addReputationPoints(30) end})
    missionMs3:setPlayer(player)
    Mission:withBroker(missionMs3, "Finden und besuchen Sie " .. miningStation3:getCallSign(), {missionBroker = hq})
    missionMs3:accept(); missionMs3:start()
    player:addMission(missionMs3)

    -- start the story
--    My.startIntro(hq, player, commander, highCommand)
end

function update(delta)
    Cron.tick(delta)
end
