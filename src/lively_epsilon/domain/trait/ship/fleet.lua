Ship = Ship or {}

Ship.withFleet = function(self, ship, fleet)
    if not isEeShip(ship) then error("Expected ship to be Ship, but got " .. type(ship), 2) end
    if Ship:hasFleet(ship) then error("Ship already has a fleet", 2) end
    if not Fleet:isFleet(fleet) then error("Expected fleet to be a fleet, but got " .. type(fleet), 2) end

    ship.getFleet = function(self) return fleet end
    ship.getFleetLeader = function(self) return fleet:getLeader() end
    ship.isFleetLeader = function(self) return fleet:getLeader() == self end

end

Ship.hasFleet = function(self, ship)
    return isEeShip(ship) and
            isFunction(ship.getFleet) and
            isFunction(ship.getFleetLeader) and
            isFunction(ship.isFleetLeader)
end