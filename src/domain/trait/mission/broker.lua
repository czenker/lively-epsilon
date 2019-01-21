Mission = Mission or {}

-- a mission that the player can accept.
--
-- It is supposed to be used for side missions that ships can give you.

Mission.withBroker = function(self, mission, title, config)
    if not Mission:isMission(mission) then error("Expected mission to be a Mission, but " .. type(mission) .. " given.", 2) end
    if Mission:isBrokerMission(mission) then error("The given mission is already a StoryMission.", 2) end
    if not isString(title) and not isFunction(title) then error("Title needs to be a string or function, but " .. type(title) .. " given.", 2) end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. type(config) .. " given.", 2) end
    if not isNil(config.description) and not isString(config.description) and not isFunction(config.description) then error("Description needs to be a string or function, but " .. type(config.description) .. " given.", 2) end
    if not isNil(config.acceptMessage) and not isString(config.acceptMessage) and not isFunction(config.acceptMessage) then error("AcceptMission needs to be a string or function, but " .. type(config.acceptMessage) .. " given.", 2) end

    -- the entity (station, ship, person, etc) who has given the mission to the player
    local missionBroker
    local parentAccept = mission.accept
    local hint

    mission.getTitle = function(self)
        if isFunction(title) then
            return title(self)
        else
            return title
        end
    end

    mission.getDescription = function(self)
        if isFunction(config.description) then
            return config.description(self)
        else
            return config.description
        end
    end

    mission.getAcceptMessage = function(self)
        if isFunction(config.acceptMessage) then
            return config.acceptMessage(self)
        else
            return config.acceptMessage
        end
    end

    mission.accept = function(self)
        if missionBroker == nil then error("The missionBroker needs to be set before calling accept", 2) end
        return parentAccept(self)
    end

    mission.setHint = function(self, thing)
        if not isNil(thing) and not isString(thing) and not isFunction(thing) then error("Expected nil, a function or string, but got " .. typeInspect(thing), 2) end
        hint = thing
    end

    mission.getHint = function(self)
        if isFunction(hint) then
            local ret = hint(self)
            if not isNil(ret) and not isString(ret) then
                logError("Expected hint callback to return a string or nil, but got " .. typeInspect(ret))
                return nil
            else return ret end
        else
            return hint
        end
    end

    mission.setMissionBroker = function(self, thing)
        missionBroker = thing
    end

    mission.getMissionBroker = function(self)
        return missionBroker
    end

    if config.missionBroker ~= nil then mission:setMissionBroker(config.missionBroker) end
    if config.hint ~= nil then mission:setHint(config.hint) end
end

Mission.isBrokerMission = function(self, thing)
    return Mission:isMission(thing) and
            isFunction(thing.getTitle) and
            isFunction(thing.getDescription) and
            isFunction(thing.getAcceptMessage) and
            isFunction(thing.setHint) and
            isFunction(thing.getHint) and
            isFunction(thing.getMissionBroker) and
            isFunction(thing.setMissionBroker)
end