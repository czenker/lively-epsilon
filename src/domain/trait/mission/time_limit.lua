Mission = Mission or {}

--- limit the time a mission is "started" before it fails automatically
--- @param self
--- @param mission Mission
--- @param timeLimit number
Mission.withTimeLimit = function(self, mission, timeLimit)
    if not Mission:isMission(mission) then error("Expected mission to be a Mission, but " .. typeInspect(mission) .. " given.", 2) end
    if mission:getState() ~= "new" then error("The mission must not be started yet, but got " .. typeInspect(mission:getState()), 2) end
    if Mission:isTimeLimitMission(mission) then error("The given mission is already has a TimeLimit.", 2) end

    local cronId = "mission_timelimit_" .. Util.randomUuid()

    local elapsedTime = 0
    local limitedTime = nil

    local parentStart = mission.start
    ---mark the mission as started
    ---@param self
    mission.start = function(self)
        if not limitedTime then error("Expected a time limit is set before starting the mission, but got " .. typeInspect(limitedTime), 2) end

        parentStart(self)

        Cron.regular(cronId, function(self, delta)
            if mission:getState() ~= "started" then
                Cron.abort(self)
            else
                elapsedTime = elapsedTime + delta
                if elapsedTime > limitedTime then
                    mission:fail()
                    Cron.abort(self)
                end
            end
        end)
    end

    --- set the duration after which the mission will automatically fail
    --- @param self
    --- @param timeLimit number
    mission.setTimeLimit = function(self, timeLimit)
        if not isNumber(timeLimit) or timeLimit <= 0 then error("Expected timeLimit to be a positive number, but got " .. typeInspect(timeLimit), 2) end

        limitedTime = timeLimit
    end

    --- get the remaining time before the mission will automatically fail
    --- @param self
    --- @return nil|number
    mission.getRemainingTime = function(self)
        if limitedTime == nil then
            return nil
        else
            return math.max(0, limitedTime - elapsedTime)
        end
    end

    --- get the time that has already elapsed since the start of the mission
    --- @param self
    --- @return number
    mission.getElapsedTime = function(self)
        return elapsedTime
    end

    --- modify the duration at which the mission will fail
    --- @param self
    --- @param delta number
    mission.modifyTimeLimit = function(self, delta)
        if not isNumber(delta) then error("Expected delta to be a number, but got " .. typeInspect(delta), 2) end
        limitedTime = limitedTime + delta
    end

    if not isNil(timeLimit) then
        mission:setTimeLimit(timeLimit)
    end

    return mission
end

--- check if the given thing is a Mission with TimeLimit
--- @param self
--- @param thing any
--- @return boolean
Mission.isTimeLimitMission = function(self, thing)
    return Mission:isMission(thing) and
            isFunction(thing.setTimeLimit) and
            isFunction(thing.getRemainingTime) and
            isFunction(thing.getElapsedTime) and
            isFunction(thing.modifyTimeLimit)

end