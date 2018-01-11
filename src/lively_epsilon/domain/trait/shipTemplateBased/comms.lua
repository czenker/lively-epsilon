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

    spaceObject.setHailText = function(self, hailText)
        if not isString(hailText) and not isNil(hailText) and not isFunction(hailText) then
            error("hailText needs to be a string or a function", 2)
        end
        theHailText = hailText
    end

    spaceObject.getHailText = function(self, player)
        if not isEePlayer(player) then error("Expected to be called with a Player, but got " .. type(player), 2) end
        if isString(theHailText) then
            return theHailText
        elseif isFunction(theHailText) then
            local reply = theHailText(self, player)
            if isString(reply) then
                return reply
            elseif not isNil(reply) then
                logWarning("Expected hail text function to return a string or nil, but got " .. type(reply), 2)
            end
        end
        return nil
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
        local ret = {}

        for k,v in pairs(comms) do
            ret[k] = v
        end

        return ret
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
    return isFunction(thing.getHailText) and
            isFunction(thing.setHailText) and
            isFunction(thing.addComms) and
            isFunction(thing.getComms)
end