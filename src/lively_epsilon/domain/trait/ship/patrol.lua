Ship = Ship or {}

local tick = 1

local function validateWaypoint(waypoint)
    return isEeStation(waypoint.target) or isVector2f(waypoint.target)
end

local function goToWaypoint(ship, waypoint)
    if isEeStation(waypoint.target) then
        ship:orderDock(waypoint.target)
    elseif isVector2f(waypoint.target) then
        local x, y = waypoint.target[1], waypoint.target[2]
        ship:orderFlyTowards(x, y)
    else
        error("invalid target to go to", 2)
    end
end

local function isWaypointReached(ship, waypoint)
    if isEeStation(waypoint.target) then
        return ship:isDocked(waypoint.target)
    elseif isVector2f(waypoint.target) then
        local x, y = waypoint.target[1], waypoint.target[2]
        return distance(ship, x, y) < 500
    else
        error("invalid target to go to", 2)
    end
end

-- target:                     SpaceStation|Vector2f
-- onHeading (optional):       function         - called when the ship is starting to head to the target
-- whileFlying (optional):     function         - called every tick while the ship is heading to the target
-- @TODO: would be nice if you could return some value in that function to prevent it from being called ever again (might be cool to trigger an event once on the flight)
-- onArrival (optional):       function         - called when the ship has arrived at target
-- delay (default = 0):        numeric          - delay before ship heads to the next waypoint
Ship.patrol = function(self, ship, waypoints)
    waypoints = Util.deepCopy(waypoints) -- prevent mutability

    if not isEeShip(ship) or not ship:isValid() then
        error("Invalid ship given", 2)
    end

    if not Util.isNumericTable(waypoints) then
        error("Waypoints should be a table with numerical indices", 2)
    end
    if Util.size(waypoints) == 0 then
        error("Waypoints should not be empty", 2)
    end
    for idx, waypoint in pairs(waypoints) do
        if not validateWaypoint(waypoint) then
            error("Waypoint with index " .. idx .. " is not a valid waypoint", 3)
        end
    end

    local cronId = "patrol_" .. ship:getCallSign()
    local currentWaypoint
    local nextWaypoint
    local waypointId = 0
    local delay = 0

    Cron.regular(cronId, function()
        if not ship:isValid() then
            print("ship for " .. cronId .. " is no longer valid")
            Cron.abort(cronId)
        elseif delay > 0 then
            delay = delay - tick
        else
            if waypointId == 0 then
                waypointId = 1
                nextWaypoint = waypoints[waypointId]
            elseif nextWaypoint == nil and currentWaypoint ~= nil then
                if isFunction(currentWaypoint.whileFlying) then
                    local status, error = pcall(currentWaypoint.whileFlying, ship, currentWaypoint.target)
                    if not status then
                        if isString(error) then
                            print("Error when calling whileFlying: " .. error)
                        else
                            print("Error when calling whileFlying")
                        end
                    end
                end

                if isWaypointReached(ship, currentWaypoint) then
                    if isFunction(currentWaypoint.onArrival) then
                        local status, error = pcall(currentWaypoint.onArrival, ship, currentWaypoint.target)
                        if not status then
                            if isString(error) then
                                print("Error when calling onArrival: " .. error)
                            else
                                print("Error when calling onArrival")
                            end
                        end
                    end

                    waypointId = waypointId + 1
                    if waypointId > Util.size(waypoints) then
                        waypointId = 1
                    end

                    if isNumber(currentWaypoint.delay) then
                        delay = currentWaypoint.delay
                    end

                    nextWaypoint = waypoints[waypointId]
                end
            end
            if delay <= 0 and nextWaypoint ~= nil then
                goToWaypoint(ship, nextWaypoint)
                currentWaypoint = nextWaypoint
                nextWaypoint = nil

                if isFunction(currentWaypoint.onHeading) then
                    local status, error = pcall(currentWaypoint.onHeading, ship, currentWaypoint.target)
                    if not status then
                        if isString(error) then
                            print("Error when calling onHeading: " .. error)
                        else
                            print("Error when calling onHeading")
                        end
                    end
                end
            end
        end
    end, tick)

end