Missions = Missions or {}

local validateWayPoints = function(wayPoints)
    if not isTable(wayPoints) then
        error("Expected wayPoints to be a table, but got " .. typeInspect(wayPoints), 2)
    end
    for i, entry in pairs(wayPoints) do
        if isEeObject(entry) then
            if not isFunction(entry.getPosition) then
                error("Expected waypoint at position " .. i .. " to have a getPosition function, but " .. typeInspect(entry) .. " does not.", 4)
            end
            local x, y = entry:getPosition()
            if not isNumber(x) then
                error("Expected getPosition in wayPoint " .. i .. " to return a valid x coordinate, but got " .. typeInspect(x), 4)
            end
            if not isNumber(y) then
                error("Expected getPosition in wayPoint " .. i .. " to return a valid y coordinate, but got " .. typeInspect(y), 4)
            end
        else
            if not isTable(entry) or Util.size(entry) ~= 2 then
                error("Expected wayPoint at position " .. i .. " to be a table with exactly two entries, but got " .. typeInspect(entry), 4)
            end
            if not isNumber(entry[1]) then
                error("Expected first coordinate in wayPoint " .. i .. " to be a number, but got " .. typeInspect(entry[1]), 4)
            end
            if not isNumber(entry[2]) then
                error("Expected second coordinate in wayPoint " .. i .. " to be a number, but got " .. typeInspect(entry[2]), 4)
            end
        end
    end
end

--- A mission to fly close to a sequence of wayPoints
---
--- @param self
--- @param wayPoints table[table[number, number]]|nil a table of coordinates that serve as wayPoints, e.g. `{{0, 0}, {42000, -1000}}`
--- @param config table
---   @field minDistance number distance to a wayPoint to count as "visited" (default: `1000`)
---   @field onWayPoint function(mission)
--- @return Mission
Missions.wayPoints = function(self, wayPoints, config)
    wayPoints = wayPoints or {}
    validateWayPoints(wayPoints)
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end
    config.minDistance = config.minDistance or 1000

    local visitedWayPoints = 0

    local cronId = Util.randomUuid()

    local mission
    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(config.onStart) then config.onStart(self) end

            Cron.regular(cronId, function()
                if wayPoints[1] ~= nil then
                    local x, y
                    if isEeObject(wayPoints[1]) then
                        x, y = wayPoints[1]:getPosition()
                    else
                        x, y = table.unpack(wayPoints[1])
                    end

                    if distance(x, y, self:getPlayer()) < config.minDistance then
                        if isFunction(config.onWayPoint) then
                            local arg1, arg2 = x, y
                            if isEeObject(wayPoints[1]) then
                                arg1, arg2 = wayPoints[1], nil
                            end
                            userCallback(config.onWayPoint, self, arg1, arg2)
                        end
                        visitedWayPoints = visitedWayPoints + 1
                        table.remove(wayPoints, 1)
                        if wayPoints[1] == nil then
                            self:success()
                        end
                    end
                else
                    self:success()
                end
            end, 0.5)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)

            if isFunction(config.onEnd) then config.onEnd(self) end
        end
    })
    Mission:forPlayer(mission)

    --- add a wayPoint to the mission.
    --- This can be done even if the mission is running, like in the onStart or onWayPoint callbacks.
    --- @param self
    --- @param xOrObject number|SpaceObject either an x/y coordinate or a SpaceObject
    --- @param y number
    mission.addWayPoint = function(self, xOrObject, y)
        if isEeObject(xOrObject) then
            if not isFunction(xOrObject.getPosition) then
                error("Expected space object to have a getPosition function, but " .. typeInspect(xOrObject) .. " does not.", 3)
            end
            local x, y = xOrObject:getPosition()
            if not isNumber(x) then
                error("Expected getPosition to return a valid x coordinate, but got " .. typeInspect(x), 3)
            end
            if not isNumber(y) then
                error("Expected getPosition to return a valid y coordinate, but got " .. typeInspect(y), 3)
            end
            table.insert(wayPoints, xOrObject)
        else
            if not isNumber(xOrObject) then error("Expected first parameter to be a number, but got " .. typeInspect(xOrObject), 3) end
            if not isNumber(y) then error("Expected first parameter to be a number, but got " .. typeInspect(y), 3) end
            table.insert(wayPoints, { xOrObject, y})
        end
    end

    --- get the number of wayPoints that have already been visited
    --- @return number
    mission.countVisitedWayPoints = function(self)
        return visitedWayPoints
    end

    return mission
end