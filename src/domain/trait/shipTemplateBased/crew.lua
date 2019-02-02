ShipTemplateBased = ShipTemplateBased or {}

--- check if the ship or station has a person at the position with name
--- @param self
--- @param position string
--- @return boolean
local function hasCrewAtPosition(self, position)
    return isTable(self.crew) and self.crew[position] ~= nil
end

--- get the person at the position
--- @param self
--- @param position string
--- @return Person|nil
local function getCrewAtPosition(self, position)
    if hasCrewAtPosition(self, position) then
        return self.crew[position]
    else
        return nil
    end
end

--- add a crew to the ShipTemplateBased
--- @param self
--- @param ship ShipTemplateBased
--- @param positions nil|table[string,Person]
--- @return ShipTemplateBased
ShipTemplateBased.withCrew = function (self, ship, positions)
    positions = positions or {}
    if not isEeShipTemplateBased(ship) or not ship:isValid() then
        error("Invalid shipTemplateBased given", 2)
    end
    for position, person in pairs(positions) do
        if not isString(position) then
            error("Position has to be a string, but got " .. typeInspect(position), 3)
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

--- check if the thing has a crew
--- @param self
--- @param ship any
--- @return boolean
ShipTemplateBased.hasCrew = function(self, ship)
    return isFunction(ship.hasCrewAtPosition) and
            isFunction(ship.getCrewAtPosition)
end