-- Helpers to create Comms conversations
Comms = Comms or {}

local addText = function(screen, text)
    screen.npcSays = screen.npcSays .. (text or "")
    return screen
end

local withReply = function(screen, reply)
    if not Comms.isReply(reply) then
        return error("The given thing is not a valid CommsReply", 2)
    end
    table.insert(screen.howPlayerCanReact, reply)
    return screen
end


Comms.screen = function(npcSays, howPlayerCanReact)
    npcSays = npcSays or ""
    howPlayerCanReact = howPlayerCanReact or {}

    if not isString(npcSays) then
        error("First parameter of newScreen has to be a string. " .. type(npcSays) .. " given.", 2)
    end
    if not isTable(howPlayerCanReact) then
        error("Second parameter of newScreen has to be a table. " .. type(howPlayerCanReact) .. " given.", 2)
    end

    for k, v in ipairs(howPlayerCanReact) do
        if not Comms.isReply(v) then
            error("Reply at index " .. k .. " is not a valid reply.", 3)
        end
    end


    return { npcSays = npcSays, howPlayerCanReact = howPlayerCanReact, withReply = withReply, addText = addText}
end

Comms.isScreen = function(thing)
    if not isTable(thing) or not (isFunction(thing.npcSays) or isString(thing.npcSays)) or not isTable(thing.howPlayerCanReact) then
        return false
    end
    for k, v in ipairs(thing.howPlayerCanReact) do
        if not Comms.isReply(v) then
            return false
        end
    end
    return true
end

Comms.reply = function(playerSays, nextScreen, condition)

    if not isFunction(playerSays) and not isString(playerSays) then
        error("First parameter of newReply has to be a string of function. " .. type(playerSays) .. " given.", 2)
    end
    if not isFunction(nextScreen) and not isNil(nextScreen) then
        error("Second parameter of newReply has to be a function. " .. type(nextScreen) .. " given.", 2)
    end
    condition = condition or function() return true end
    if not isFunction(condition) then
        error("Third parameter of newReply has to be a function. " .. type(condition) .. " given.", 2)
    end

    local pSays
    if isString(playerSays) then
        pSays = function(station, player) return playerSays end
    else
        pSays = playerSays
    end

    return { playerSays = pSays, nextScreen = nextScreen, condition = condition }
end

Comms.isReply = function(thing)
    return isTable(thing) and isFunction(thing.playerSays) and (isFunction(thing.nextScreen) or isNil(thing.nextScreen))
end