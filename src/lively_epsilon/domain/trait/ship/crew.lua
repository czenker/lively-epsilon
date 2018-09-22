Ship = Ship or {}

local function filterRandomObject(station, filterFunction, radius)
    local x, y = station:getPosition()
    radius = radius or getLongRangeRadarRange()

    local objects = {}
    for k, object in pairs(getObjectsInRadius(x, y, radius)) do
        if filterFunction(object) then objects[k] = object end
    end

    return Util.random(objects)
end

local function hasCrewAtPosition(ship, position)
    return isTable(ship.crew) and ship.crew[position] ~= nil
end

local function getCrewAtPosition(ship, position)
    if hasCrewAtPosition(ship, position) then
        return ship.crew[position]
    else
        return nil
    end
end

Ship.withCrew = function (self, ship, positions)
    positions = positions or {}
    if not (isEeShip(ship) or isEePlayer(ship)) or not ship:isValid() then
        error("Invalid ship given", 2)
    end
    for position, person in pairs(positions) do
        if not isString(position) then
            error("Position has to be a string. " .. type(position) .. " given.")
        end
        if not Person.isPerson(person) then
            error("Thing given for position " .. position .. " is not a Person object.")
        end
    end

    if not Ship:hasCrew(ship) then
        ship.crew = {}
        ship.hasCrewAtPosition = hasCrewAtPosition
        ship.hasCaptain = function() return hasCrewAtPosition(ship, "captain") end
        ship.hasHelmsOfficer = function() return hasCrewAtPosition(ship, "helms") end
        ship.hasRelayOfficer = function() return hasCrewAtPosition(ship, "relay") end
        ship.hasScienceOfficer = function() return hasCrewAtPosition(ship, "science") end
        ship.hasWeaponsOfficer = function() return hasCrewAtPosition(ship, "weapons") end
        ship.hasEngineeringOfficer = function() return hasCrewAtPosition(ship, "engineering") end
        ship.getCrewAtPosition = getCrewAtPosition
        ship.getCaptain = function() return getCrewAtPosition(ship, "captain") end
        ship.getHelmsOfficer = function() return getCrewAtPosition(ship, "helms") end
        ship.getRelayOfficer = function() return getCrewAtPosition(ship, "relay") end
        ship.getScienceOfficer = function() return getCrewAtPosition(ship, "science") end
        ship.getWeaponsOfficer = function() return getCrewAtPosition(ship, "weapons") end
        ship.getEngineeringOfficer = function() return getCrewAtPosition(ship, "engineering") end
    end

    for position, person in pairs(positions) do
        ship.crew[position] = person
    end

    return ship
end

Ship.withCaptain = function(self, ship, person) Ship.withCrew(self, ship, {captain = person}) end
Ship.withHelmsOfficer = function(self, ship, person) Ship.withCrew(self, ship, {helms = person}) end
Ship.withRelayOfficer = function(self, ship, person) Ship.withCrew(self, ship, {relay = person}) end
Ship.withScienceOfficer = function(self, ship, person) Ship.withCrew(self, ship, {science = person}) end
Ship.withWeaponsOfficer = function(self, ship, person) Ship.withCrew(self, ship, {weapons = person}) end
Ship.withEngineeringOfficer = function(self, ship, person) Ship.withCrew(self, ship, {engineering = person}) end

Ship.hasCrew = function(self, ship)
    return isFunction(ship.hasCrewAtPosition) and
            isFunction(ship.hasCaptain) and
            isFunction(ship.hasHelmsOfficer) and
            isFunction(ship.hasRelayOfficer) and
            isFunction(ship.hasScienceOfficer) and
            isFunction(ship.hasWeaponsOfficer) and
            isFunction(ship.hasEngineeringOfficer) and
            isFunction(ship.getCrewAtPosition) and
            isFunction(ship.getCaptain) and
            isFunction(ship.getHelmsOfficer) and
            isFunction(ship.getRelayOfficer) and
            isFunction(ship.getScienceOfficer) and
            isFunction(ship.getWeaponsOfficer) and
            isFunction(ship.getEngineeringOfficer)
end