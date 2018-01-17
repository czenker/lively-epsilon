ShipTemplateBased = ShipTemplateBased or {}

ShipTemplateBased.withComms = function (self, spaceObject, config)
    if not isEeShipTemplateBased(spaceObject) then
        error ("Expected a shipTemplateBased object but got " .. type(spaceObject), 2)
    end
    if ShipTemplateBased:hasComms(spaceObject) then
        error("Object with call sign " .. spaceObject:getCallSign() .. " already has comms configured.", 2)
    end

    config = config or {}
    if not isTable(config) then
        error("Expected config to be a table, but " .. type(config) .. " given.", 2)
    end

    local comms = {}
    local theHailText
    local overriddenComms
    local overriddenCommsOnce

    spaceObject.setHailText = function(self, hailText)
        if not isString(hailText) and not isNil(hailText) and not isFunction(hailText) then
            error("hailText needs to be a string or a function", 2)
        end
        theHailText = hailText
    end

    spaceObject.addComms = function(self, reply, id)
        if not Comms.isReply(reply) then error("Expected reply to be a reply, but got " .. type(reply), 2) end
        id = id or Util.randomUuid()
        if not isString(id) then error("Expected id to be a string, but got " .. type(id), 2) end

        comms[id] = reply

        return id
    end

    spaceObject.getComms = function(self, player)
        if not isEePlayer(player) then error("Expected a Player, but got " .. type(player), 2) end
        if overriddenComms ~= nil then
            if overriddenCommsOnce == true then
                local tmp = overriddenComms
                overriddenComms = nil
                return tmp
            else
                return overriddenComms
            end
        else
            local howPlayerCanReact = {}

            for k,v in pairs(comms) do
                howPlayerCanReact[k] = v
            end

            local hailText
            if isNil(theHailText) or isString(theHailText) then
                hailText = theHailText
            elseif isFunction(theHailText) then
                hailText = theHailText(self, player)
                if not isString(hailText) and not isNil(hailText) then
                    logWarning("Expected hail text function to return a string or nil, but got " .. type(hailText), 2)
                    hailText = nil
                end
            end
            return Comms.screen(hailText, howPlayerCanReact)
        end
    end

    spaceObject.overrideComms = function(self, screen, once)
        if not Comms.isScreen(screen) and not isNil(screen) then error("Expected a screen, but got " .. type(screen), 2) end
        once = once or false
        if not isBoolean(once) then error("Expected a boolean, but got " .. type(once), 2) end

        overriddenComms = screen
        overriddenCommsOnce = once
    end

    spaceObject:setCommsScript("src/lively_epsilon/scripts/comms.lua")

    if not isNil(config.hailText) then
        spaceObject:setHailText(config.hailText)
    end

    if isTable(config.comms) then
        for id,comms in pairs(config.comms) do
            if isNumber(id) then id = nil end
            spaceObject:addComms(comms, id)
        end
    elseif not isNil(config.comms) then
        error("Expected comms to be a table of comms, but got " .. type(config.comms), 2)
    end
end

ShipTemplateBased.hasComms = function(self, thing)
    return isFunction(thing.setHailText) and
            isFunction(thing.addComms) and
            isFunction(thing.getComms) and
            isFunction(thing.overrideComms)
end