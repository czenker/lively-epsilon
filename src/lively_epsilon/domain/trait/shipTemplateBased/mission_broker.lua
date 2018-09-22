ShipTemplateBased = ShipTemplateBased or {}

ShipTemplateBased.withMissionBroker = function (self, spaceObject, config)
    if not isEeShipTemplateBased(spaceObject) then error ("Expected a shipTemplateBased object but got " .. type(spaceObject), 2) end
    if ShipTemplateBased:hasMissionBroker(spaceObject) then error ("Object with call sign " .. spaceObject:getCallSign() .. " already has a mission broker.", 2) end

    config = config or {}
    if not isTable(config) then
        error("Expected config to be a table, but " .. type(config) .. " given.", 2)
    end
    if not isNil(config.missions) and not isTable(config.missions) then error("Missions need to be a table, but got " .. type(config.missions)) end

    local missions = {}

    spaceObject.addMission = function(self, mission)

        if not Mission.isBrokerMission(mission) then
            error("Expected mission to be a broker mission, but " .. type(mission) .. " given.", 2)
        end

        missions[mission:getId()] = mission
    end

    spaceObject.removeMission = function(self, mission)
        if isString(mission) then
            missions[mission] = nil
        elseif Mission:isMission(mission) then
            missions[mission:getId()] = nil
        else
            error("Expected mission to be a mission or mission id, but " .. type(mission) .. " given.", 2)
        end
    end

    spaceObject.getMissions = function(self)
        local ret = {}
        for _,mission in pairs(missions) do
            table.insert(ret, mission)
        end
        return ret
    end

    spaceObject.hasMissions = function(self)
        for _,_ in pairs(missions) do
            return true
        end
        return false
    end

    for _, mission in pairs(config.missions or {}) do
        spaceObject:addMission(mission)
    end
end

ShipTemplateBased.hasMissionBroker = function(self, thing)
    return isFunction(thing.addMission) and
            isFunction(thing.removeMission) and
            isFunction(thing.getMissions) and
            isFunction(thing.hasMissions)
end