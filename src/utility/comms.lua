-- Helpers to create Comms conversations
Comms = Comms or {}

--- add text to the screen
--- @param screen CommsScreen
--- @param text string
--- @return CommsScreen
local addText = function(screen, text)
    screen.npcSays = screen.npcSays .. (text or "")
    return screen
end

--- add a reply to the screen
--- @param screen CommsScreen
--- @param reply CommsReply
--- @return CommsScreen
local withReply = function(screen, reply)
    if not Comms:isReply(reply) then
        return error("The given thing is not a valid CommsReply", 2)
    end
    table.insert(screen.howPlayerCanReact, reply)
    return screen
end

--- creates a CommsScreen
--- @param npcSays string what the NPC says (aka longish text)
--- @param howPlayerCanReact table[CommsReply] possible answers of the player
--- @return CommsScreen
Comms.screen = function(npcSays, howPlayerCanReact)
    npcSays = npcSays or ""
    howPlayerCanReact = howPlayerCanReact or {}

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
        npcSays = npcSays,
        howPlayerCanReact = howPlayerCanReact,
        withReply = withReply,
        addText = addText
    }
end

--- check if the given thing is a valid `CommsScreen`
--- @param self
--- @param thing any
--- @return boolean
Comms.isScreen = function(self, thing)
    if not isTable(thing) or not (isFunction(thing.npcSays) or isString(thing.npcSays)) or not isTable(thing.howPlayerCanReact) then
        return false
    end
    for k, v in ipairs(thing.howPlayerCanReact) do
        if not Comms:isReply(v) then
            return false
        end
    end
    return true
end

--- creates a CommsReply
--- @param playerSays string|function the short statement from the players
--- @param nextScreen nil|function get the next screen that should be displayed to the players
--- @param condition nil|function the condition under which this option should be displayed
--- @return CommsReply
Comms.reply = function(playerSays, nextScreen, condition)

    if not isFunction(playerSays) and not isString(playerSays) then
        error("First parameter of newReply has to be a string of function, but got " .. typeInspect(playerSays), 2)
    end
    if not isFunction(nextScreen) and not isNil(nextScreen) then
        error("Second parameter of newReply has to be a function, but got " .. typeInspect(nextScreen), 2)
    end
    condition = condition or function() return true end
    if not isFunction(condition) then
        error("Third parameter of newReply has to be a function, but got " .. typeInspect(condition), 2)
    end

    local pSays
    if isString(playerSays) then
        pSays = function(station, player) return playerSays end
    else
        pSays = playerSays
    end

    return {
        playerSays = pSays,
        nextScreen = nextScreen,
        condition = condition
    }
end

--- check if the given thing is a valid `CommsReply`
--- @param self
--- @param thing any
--- @return boolean
Comms.isReply = function(self, thing)
    return isTable(thing) and isFunction(thing.playerSays) and (isFunction(thing.nextScreen) or isNil(thing.nextScreen))
end