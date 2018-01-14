require("resources/comms/human_command.lua")
require("resources/comms/human_merchant.lua")
require("resources/comms/human_mission_broker.lua")
require("resources/comms/human_hail.lua")

function MyPlayer(player)
    local player = player or PlayerSpaceship()

    Player:withStorage(player)
    Player:withStorageDisplay(player)

    Player:withMissionTracker(player)
    Player:withMissionDisplay(player)

    return player
end

function MySpaceStation(station)
    local station = station or SpaceStation()

    Station:withComms(station)
    station:setHailText(humanStationHail)
    station:addComms(humanMerchantComms)
    station:addComms(humanMissionBrokerComms)

    Station:withTags(station)

    return station
end

function MyCpuShip(ship)
    local ship = ship or CpuShip()

    Ship:withCaptain(ship, Person:newHuman())

    Ship:withComms(ship)
    ship:setHailText(humanShipHail)
    ship:addComms(humanCommandComms)

    Ship:withTags(ship)

    return ship
end
