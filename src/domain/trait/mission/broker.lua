Mission = Mission or {}

--- A mission that the player can accept.
--- It is supposed to be used for side missions that ships can give you.
--- @param self
--- @param mission Mission
--- @param title string the title of this mission
--- @param config table
---   @field description string the description of the mission
---   @field acceptMessage string the response the player get when the accept the message
---   @field missionBroker ShipTemplateBased the party that issued this mission
---   @field hint string a hint for this mission
Mission.withBroker = function(self, mission, title, config)
    if not Mission:isMission(mission) then error("Expected mission to be a Mission, but " .. typeInspect(mission) .. " given.", 2) end
    if mission:getState() ~= "new" then error("The mission must not be started yet, but got " .. typeInspect(mission:getState()), 2) end
    if Mission:isBrokerMission(mission) then error("The given mission is already a StoryMission.", 2) end
    if not isString(title) and not isFunction(title) then error("Title needs to be a string or function, but " .. typeInspect(title) .. " given.", 2) end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end
    if not isNil(config.description) and not isString(config.description) and not isFunction(config.description) then error("Description needs to be a string or function, but " .. typeInspect(config.description) .. " given.", 2) end
    if not isNil(config.acceptMessage) and not isString(config.acceptMessage) and not isFunction(config.acceptMessage) then error("AcceptMission needs to be a string or function, but " .. typeInspect(config.acceptMessage) .. " given.", 2) end

    -- the entity (station, ship, person, etc) who has given the mission to the player
    local missionBroker
    local parentAccept = mission.accept
    local hint

    ---get the printable title of this mission
    ---@param self
    --- @return string
    mission.getTitle = function(self)
        if isFunction(title) then
            return title(self)
        else
            return title
        end
    end

    ---get the printable description of this mission
    ---@param self
    ---@return string
    mission.getDescription = function(self)
        if isFunction(config.description) then
            return config.description(self)
        else
            return config.description
        end
    end

    ---get the printable response when the mission has been accepted
    ---@param self
    ---@return string
    mission.getAcceptMessage = function(self)
        if isFunction(config.acceptMessage) then
            return config.acceptMessage(self)
        else
            return config.acceptMessage
        end
    end

    ---mark the mission as accepted. `setMissionBroker` needs to have been called beforehand.
    ---@param self
    ---@return nil
    mission.accept = function(self)
        if missionBroker == nil then error("The missionBroker needs to be set before calling accept", 2) end
        return parentAccept(self)
    end

    local parentStart = mission.start
    ---mark the mission as started
    ---@param self
    --- @return nil
    mission.start = function(self)
        parentStart(self)

        Cron.regular(function(self)
            if mission:getState() ~= "started" then
                Cron.abort(self)
            elseif not mission:getMissionBroker() or not mission:getMissionBroker():isValid() then
                mission:fail()
                Cron.abort(self)
            end
        end, 0.1)
    end

    ---set a printable hint that can be displayed in the Mission Tracker
    ---@param self
    ---@param thing string|function
    mission.setHint = function(self, thing)
        if not isNil(thing) and not isString(thing) and not isFunction(thing) then error("Expected nil, a function or string, but got " .. typeInspect(thing), 2) end
        hint = thing
    end

    ---get a printable hint for the current state of the mission
    ---@param self
    ---@return nil|string
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

    ---set the broker that has offered this mission
    ---@param self
    ---@param thing ShipTemplateBased
    mission.setMissionBroker = function(self, thing)
        missionBroker = thing
    end

    --- get the broker that has offered this mission
    --- @param self
    --- @return ShipTemplateBased
    mission.getMissionBroker = function(self)
        return missionBroker
    end

    if config.missionBroker ~= nil then mission:setMissionBroker(config.missionBroker) end
    if config.hint ~= nil then mission:setHint(config.hint) end

    return mission
end

--- check if the given thing is a broker mission
--- @param self
--- @param thing any
--- @return boolean
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