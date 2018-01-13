function MySpaceStation(station)
    local station = station or SpaceStation()
    Station:withComms(station)
    Station:withTags(station)
    station:setHailText("Hello World")
    return station
end

function MyCpuShip(ship)
    local ship = ship or CpuShip()
    Ship:withCaptain(ship, Person:newHuman())

    Ship:withComms(ship)
    ship:setHailText(function(self, player)
        return "Hello " .. player:getCallSign() .. ".\n\nThis is Captain " .. self:getCrewAtPosition("captain"):getFormalName() .. " of " .. self:getCallSign() .. ". How can I help you?"
    end)
    Ship:withTags(ship)

    return ship
end
