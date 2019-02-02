ShipTemplateBased = ShipTemplateBased or {}

--- let them have a mission broker
--- @param self
--- @param spaceObject ShipTemplateBased
--- @param config table
---   @field missions table[Mission]
--- @return ShipTemplateBased
ShipTemplateBased.withMissionBroker = function (self, spaceObject, config)
    if not isEeShipTemplateBased(spaceObject) then error ("Expected a shipTemplateBased object but got " .. typeInspect(spaceObject), 2) end
    if ShipTemplateBased:hasMissionBroker(spaceObject) then error ("Object with call sign " .. spaceObject:getCallSign() .. " already has a mission broker.", 2) end

    config = config or {}
    if not isTable(config) then
        error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2)
    end
    if not isNil(config.missions) and not isTable(config.missions) then error("Missions need to be a table, but got " .. typeInspect(config.missions)) end

    local missions = {}

    --- add a mission to the broker
    --- @param self
    --- @param mission Mission
    --- @return ShipTemplateBased
    spaceObject.addMission = function(self, mission)

        if not Mission:isBrokerMission(mission) then
            error("Expected mission to be a broker mission, but " .. typeInspect(mission) .. " given.", 2)
        end

        missions[mission:getId()] = mission

        return self
    end

    --- remove a mission
    --- @param self
    --- @param mission string|Mission
    --- @return ShipTemplateBased
    spaceObject.removeMission = function(self, mission)
        if isString(mission) then
            missions[mission] = nil
        elseif Mission:isMission(mission) then
            missions[mission:getId()] = nil
        else
            error("Expected mission to be a mission or mission id, but " .. typeInspect(mission) .. " given.", 2)
        end

        return self
    end

    --- get all missions
    --- @param self
    --- @return table[Mission]
    spaceObject.getMissions = function(self)
        local ret = {}
        for _,mission in pairs(missions) do
            table.insert(ret, mission)
        end
        return ret
    end

    --- check if the broker has any mision to offer
    --- @param self
    --- @return boolean
    spaceObject.hasMissions = function(self)
        for _,_ in pairs(missions) do
            return true
        end
        return false
    end

    for _, mission in pairs(config.missions or {}) do
        spaceObject:addMission(mission)
    end

    return spaceObject
end

--- check if the given thing has a mission broker
--- @param self
--- @param thing any
--- @return boolean
ShipTemplateBased.hasMissionBroker = function(self, thing)
    return isTable(thing) and
            isFunction(thing.addMission) and
            isFunction(thing.removeMission) and
            isFunction(thing.getMissions) and
            isFunction(thing.hasMissions)
end