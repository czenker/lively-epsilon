-- Helpers to create Comms conversations
Comms = Comms or {}

--- creates a CommsScreen
--- @param self
--- @param npcSays string what the NPC says (aka longish text)
--- @param howPlayerCanReact table[CommsReply] possible answers of the player
--- @return CommsScreen
Comms.newScreen = function(self, npcSays, howPlayerCanReact)
    npcSays = npcSays or ""
    howPlayerCanReact = howPlayerCanReact or {}

    --- add text to the screen
    --- @param self
    --- @param text string
    --- @return CommsScreen
    local addText = function(self, text)
        npcSays = npcSays .. (text or "")
        return self
    end

    --- add a reply to the screen
    --- @param self
    --- @param reply CommsReply
    --- @return CommsScreen
    local addReply = function(self, reply)
        if not Comms:isReply(reply) then
            return error("The given thing is not a valid CommsReply", 2)
        end
        table.insert(howPlayerCanReact, reply)
        return self
    end

    if not isString(npcSays) then
        error("First parameter of newScreen has to be a string, but got " .. typeInspect(npcSays), 2)
    end
    if not isTable(howPlayerCanReact) then
        error("Second parameter of newScreen has to be a table, but got " .. typeInspect(howPlayerCanReact), 2)
    end

    for k, v in ipairs(howPlayerCanReact) do
        if not Comms:isReply(v) then
            error("Reply at index " .. k .. " is not a valid reply.", 3)
        end
    end

    return {
        --- @internal
        --- @param self
        --- @return string
        getWhatNpcSays = function(self) return npcSays end,

        --- @internal
        --- @param self
        --- @return table[CommsReply]
        getHowPlayerCanReact = function(self) return howPlayerCanReact end,
        addReply = addReply,
        addText = addText,
    }
end

--- check if the given thing is a valid `CommsScreen`
--- @param self
--- @param thing any
--- @return boolean
Comms.isScreen = function(self, thing)
    return isTable(thing) and
        isFunction(thing.getWhatNpcSays) and
        isFunction(thing.getHowPlayerCanReact) and
        isFunction(thing.addReply) and
        isFunction(thing.addText)
end

--- creates a CommsReply
--- @param self
--- @param playerSays string|function the short statement from the players
--- @param nextScreen nil|function get the next screen that should be displayed to the players
--- @param condition nil|function the condition under which this option should be displayed
--- @return CommsReply
Comms.newReply = function(self, playerSays, nextScreen, condition)

    local getWhatPlayerSays
    if isString(playerSays) then
        --- @internal
        --- @param self
        --- @param station ShipTemplateBased
        --- @param player PlayerSpaceship
        getWhatPlayerSays = function(self, station, player) return playerSays end
    elseif isFunction(playerSays) then
        getWhatPlayerSays = function(self, station, player)
            return playerSays(station, player)
        end
    else
        error("Expected playerSays to be a string or function, but got " .. typeInspect(playerSays), 2)
    end

    local getNextScreen
    if isNil(nextScreen) or Comms:isScreen(nextScreen) then
        --- @internal
        --- @param self
        --- @param station ShipTemplateBased
        --- @param player PlayerSpaceship
        getNextScreen = function(self, station, player) return nextScreen end
    elseif isFunction(nextScreen) then
        getNextScreen = function(self, station, player)
            return nextScreen(station, player)
        end
    else
        error("Expected nextScreen to be nil or a function, but got " .. typeInspect(nextScreen), 2)
    end

    local checkCondition
    if isNil(condition) then
        --- check if this option is supposed to be displayed
        --- @internal
        --- @param self
        --- @param station ShipTemplateBased
        --- @param player PlayerSpaceship
        checkCondition = function(self, station, player)
            return true
        end
    elseif isFunction(condition) then
        checkCondition = function(self, station, player)
            return condition(station, player)
        end
    else
        error("Expected condition to be nil or a function, but got " .. typeInspect(condition), 2)
    end

    return {
        getWhatPlayerSays = getWhatPlayerSays,
        getNextScreen = getNextScreen,
        checkCondition = checkCondition,
    }
end

--- check if the given thing is a valid `CommsReply`
--- @param self
--- @param thing any
--- @return boolean
Comms.isReply = function(self, thing)
    return isTable(thing) and
            isFunction(thing.getWhatPlayerSays) and
            isFunction(thing.getNextScreen) and
            isFunction(thing.checkCondition)
end