Ship = Ship or {}

--- allow ships to have named crews
--- @param self
--- @param ship CpuShip
--- @param positions table[string,Person]
--- @return CpuShip
Ship.withCrew = function (self, ship, positions)
    positions = positions or {}
    if not (isEeShip(ship) or isEePlayer(ship)) or not ship:isValid() then
        error("Invalid ship given", 2)
    end
    ShipTemplateBased.withCrew(self, ship, positions)

    if not Ship:hasCrew(ship) then
        ship.hasCaptain = function() return ship:hasCrewAtPosition("captain") end
        ship.hasHelmsOfficer = function() return ship:hasCrewAtPosition("helms") end
        ship.hasRelayOfficer = function() return ship:hasCrewAtPosition("relay") end
        ship.hasScienceOfficer = function() return ship:hasCrewAtPosition("science") end
        ship.hasWeaponsOfficer = function() return ship:hasCrewAtPosition("weapons") end
        ship.hasEngineeringOfficer = function() return ship:hasCrewAtPosition("engineering") end
        ship.getCaptain = function() return ship:getCrewAtPosition("captain") end
        ship.getHelmsOfficer = function() return ship:getCrewAtPosition("helms") end
        ship.getRelayOfficer = function() return ship:getCrewAtPosition("relay") end
        ship.getScienceOfficer = function() return ship:getCrewAtPosition("science") end
        ship.getWeaponsOfficer = function() return ship:getCrewAtPosition("weapons") end
        ship.getEngineeringOfficer = function() return ship:getCrewAtPosition("engineering") end
    end

    return ship
end

--- set a captain for the ship
--- @param self
--- @param ship CpuShip
--- @param person Person
--- @return CpuShip
Ship.withCaptain = function(self, ship, person) return Ship.withCrew(self, ship, {captain = person}) end

--- set a helms officer for the ship
--- @param self
--- @param ship CpuShip
--- @param person Person
--- @return CpuShip
Ship.withHelmsOfficer = function(self, ship, person) return Ship.withCrew(self, ship, {helms = person}) end

--- set a relay officer for the ship
--- @param self
--- @param ship CpuShip
--- @param person Person
--- @return CpuShip
Ship.withRelayOfficer = function(self, ship, person) return Ship.withCrew(self, ship, {relay = person}) end

--- set a science officer for the ship
--- @param self
--- @param ship CpuShip
--- @param person Person
--- @return CpuShip
Ship.withScienceOfficer = function(self, ship, person) return Ship.withCrew(self, ship, {science = person}) end

--- set a weapons officer for the ship
--- @param self
--- @param ship CpuShip
--- @param person Person
--- @return CpuShip
Ship.withWeaponsOfficer = function(self, ship, person) return Ship.withCrew(self, ship, {weapons = person}) end

--- set an engineer officer for the ship
--- @param self
--- @param ship CpuShip
--- @param person Person
--- @return CpuShip
Ship.withEngineeringOfficer = function(self, ship, person) return Ship.withCrew(self, ship, {engineering = person}) end

--- check if the given thing is a `CpuShip` with crew
--- @param self
--- @param ship any
--- @return boolean
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