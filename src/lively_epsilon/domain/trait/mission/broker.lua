Mission = Mission or {}

-- a mission that the player can accept.
--
-- It is supposed to be used for side missions that ships can give you.

Mission.withBroker = function(self, mission, title, config)
    if not Mission.isMission(mission) then error("Expected mission to be a Mission, but " .. type(mission) .. " given.", 2) end
    if Mission.isBrokerMission(mission) then error("The given mission is already a StoryMission.", 2) end
    if not isString(title) and not isFunction(title) then error("Title needs to be a string or function, but " .. type(title) .. " given.", 2) end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. type(config) .. " given.", 2) end
    if not isNil(config.description) and not isString(config.description) and not isFunction(config.description) then error("Description needs to be a string or function, but " .. type(config.description) .. " given.", 2) end
    if not isNil(config.acceptMessage) and not isString(config.acceptMessage) and not isFunction(config.acceptMessage) then error("AcceptMission needs to be a string or function, but " .. type(config.acceptMessage) .. " given.", 2) end

    -- the entity (station, ship, person, etc) who has given the mission to the player
    local missionBroker
    -- the player who has accepted the mission
    local player
    local parentAccept = mission.accept

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
        if player == nil then error("The player has to be set before calling accept") end
        parentAccept(self)
    end

    mission.setMissionBroker = function(self, thing)
        missionBroker = thing
    end

    mission.getMissionBroker = function(self)
        return missionBroker
    end

    mission.setPlayer = function(self, thing)
        if not isEePlayer(thing) then error("Expected player to be a Player, but " .. type(thing) .. " given.", 2) end
        player = thing
    end

    mission.getPlayer = function(self)
        return player
    end
end

Mission.isBrokerMission = function(thing)
    return Mission.isMission(thing) and
            isFunction(thing.getTitle) and
            isFunction(thing.getDescription) and
            isFunction(thing.getAcceptMessage) and
            isFunction(thing.getMissionBroker) and
            isFunction(thing.setMissionBroker) and
            isFunction(thing.getPlayer) and
            isFunction(thing.setPlayer)
end