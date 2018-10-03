ShipTemplateBased = ShipTemplateBased or {}

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

ShipTemplateBased.withCrew = function (self, ship, positions)
    positions = positions or {}
    if not isEeShipTemplateBased(ship) or not ship:isValid() then
        error("Invalid shipTemplateBased given", 2)
    end
    for position, person in pairs(positions) do
        if not isString(position) then
            error("Position has to be a string. " .. type(position) .. " given.")
        end
        if not Person:isPerson(person) then
            error("Thing given for position " .. position .. " is not a Person object.")
        end
    end

    if not ShipTemplateBased:hasCrew(ship) then
        ship.crew = {}
        ship.hasCrewAtPosition = hasCrewAtPosition
        ship.getCrewAtPosition = getCrewAtPosition
    end

    for position, person in pairs(positions) do
        ship.crew[position] = person
    end

    return ship
end

ShipTemplateBased.hasCrew = function(self, ship)
    return isFunction(ship.hasCrewAtPosition) and
            isFunction(ship.getCrewAtPosition)
end