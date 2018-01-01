Station = Station or {}
-- enhances a station to have a black board with (side-) missions for the player
Station.withMissions = function (self, station)
    if not isEeStation(station) then
        error ("Expected a station but got " .. type(station), 2)
    end

    if Station:hasMissions(station) then
        -- @TODO: Would be better to check if "our" implementation is used and if not raise an error.
        return
    end

    local missions = {}

    station.addMission = function(self, mission)
        missions[mission.id] = mission
    end

    station.removeMission = function(self, mission)
        if mission.id ~= nil then
            mission = mission.id
        end
        missions[mission] = nil
    end

    station.clearMissions = function (self)
        missions = {}
    end

    station.getMissions = function(self)
        return missions
    end

    station.hasMissions = function (self)
        for _,_ in pairs(missions) do
            return true
        end
        return false
    end

    return self
end

--- checks if the given object is able to offer missions
-- @param station
-- @return boolean
Station.hasMissions = function(self, station)
    return isFunction(station.addMission) and
        isFunction(station.removeMission) and
        isFunction(station.clearMissions) and
        isFunction(station.getMissions) and
        isFunction(station.hasMissions)
end