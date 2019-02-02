Ship = Ship or {}

--- mark that a ship is part of a fleet
--- @internal
--- @param self
--- @param ship CpuShip
--- @param fleet Fleet
--- @return CpuShip
Ship.withFleet = function(self, ship, fleet)
    if not isEeShip(ship) then error("Expected ship to be Ship, but got " .. typeInspect(ship), 2) end
    if Ship:hasFleet(ship) then error("Ship already has a fleet", 2) end
    if not Fleet:isFleet(fleet) then error("Expected fleet to be a fleet, but got " .. typeInspect(fleet), 2) end

    --- get the fleet this ship is belonging to
    --- @param self
    --- @return Fleet
    ship.getFleet = function(self) return fleet end

    --- get the fleet leader of the ships fleet
    --- @param self
    --- @return CpuShip|nil
    ship.getFleetLeader = function(self) return fleet:getLeader() end

    --- check if the current ship is leader of a fleet
    --- @param self
    --- @return boolean
    ship.isFleetLeader = function(self) return fleet:getLeader():isValid() and fleet:getLeader():getCallSign() == self:getCallSign() end

    return ship
end

--- check if a ship is part of a fleet
--- @param self
--- @param ship any
--- @return boolean
Ship.hasFleet = function(self, ship)
    return isEeShip(ship) and
            isFunction(ship.getFleet) and
            isFunction(ship.getFleetLeader) and
            isFunction(ship.isFleetLeader)
end