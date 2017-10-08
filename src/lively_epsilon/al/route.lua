-- handling ships that follow a specific route
--

-- Warning: seems broken - regularily makes the game crash when ending the scenario (as far as I experienced not during game play)

local tick = 1

local ships = {}

local function updateCron()
    if Util.size(ships) > 0 then
        Cron.regular("route", function() AlRoute.update() end, tick)
    else
        Cron.abort("route")
    end
end

AlRoute = {
    --
    -- ship:                         CpuShip
    -- onBeginning (optional)        function         - called when the ship heads to the first waypoint
    -- waypoints:
    --   target:                     SpaceStation
    --   onHeading (optional):       function         - called when the ship is starting to head to the target
    --   onApproaching (optional)    function         - called when ship is close to docking
    --   onDocking (optional):       function         - called when the ship is docked to the station
    --   dockingTime (default = 0):  float            - delay before ship heads to the next waypoint
    -- onFinish (optional):          function         - called when all waypoints have been visited and the last dockingTime has elapsed
    -- onDestruction (optional):     function         - called when ship is destroyed while being active in this module
    add = function(object)
        object = Util.deepCopy(object)

        if not isEeShip(object.ship) then
            error("AlRoute.add requires the object to contain a ship", 2)
        end
        if type(object.waypoints) ~= "table" or Util.size(object.waypoints) == 0 then
            error("AlRoute.add requires the object to contain at least one waypoint", 2)
        end

        ships[object.ship:getCallSign()] = object
        updateCron()
    end,

    loop = function(object)
        object = Util.deepCopy(object)

        object.onFinish = function()
            AlRoute.loop(object)
        end

        AlRoute.add(object)
    end,

    update = function()
        for key, ship in pairs(ships) do
            if not ship.ship:isValid() then
                -- if: ship does not exist anymore
                if type(ship.onDestruction) == "function" then
                    ship.onDestruction()
                end
                ships[key] = nil
                updateCron()
            elseif type(ship.onBeginning) == "function" then
                ship.onBeginning()
                ship.onBeginning = nil
            elseif ship.currentDelay ~= nil and ship.currentDelay > 0 then
                -- if: ship is currently docking at station
                ship.currentDelay = ship.currentDelay - tick
            elseif ship.currentTarget == nil then
                local nextTarget = table.remove(ship.waypoints, 1)
                if nextTarget == nil then
                    -- if: last target was reached
                    ships[key] = nil
                    updateCron()
                    if type(ship.onFinish) == "function" then
                        ship.onFinish()
                    end
                else
                    -- if: head to next target
                    ship.currentTarget = nextTarget
                    ship.ship:orderDock(nextTarget.target)
                    if type(ship.currentTarget.onHeading) == "function" then
                        ship.currentTarget.onHeading()
                    end
                end
            elseif ship.ship:isDocked(ship.currentTarget.target) then
                -- if: ship reached its current destination
                if type(ship.currentTarget.onDocking) == "function" then
                    ship.currentTarget.onDocking()
                end
                if ship.currentTarget.dockingTime ~= nil then
                    ship.currentDelay = ship.currentTarget.dockingTime
                end
                ship.currentTarget = nil
            elseif type(ship.currentTarget.onApproaching) == "function" and (distance(ship.ship, ship.currentTarget.target) < getLongRangeRadarRange() / 4) then
                ship.currentTarget.onApproaching()
                ship.currentTarget.onApproaching = nil
            end

        end
    end
}