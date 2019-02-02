ShipTemplateBased = ShipTemplateBased or {}

--- add an improved api to set comms
--- @param self
--- @param spaceObject ShipTemplateBased
--- @param config table
---   @field hailText string|function
---   @field comms table[CommsReply]
--- @return ShipTemplateBased
ShipTemplateBased.withComms = function (self, spaceObject, config)
    if not isEeShipTemplateBased(spaceObject) then
        error ("Expected a shipTemplateBased object but got " .. typeInspect(spaceObject), 2)
    end
    if ShipTemplateBased:hasComms(spaceObject) then
        error("Object with call sign " .. spaceObject:getCallSign() .. " already has comms configured.", 2)
    end

    config = config or {}
    if not isTable(config) then
        error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2)
    end

    local comms = {}
    local theHailText
    local overriddenComms
    local overriddenCommsOnce

    --- set the hail text
    --- @param self
    --- @param hailText nil|string|function
    --- @return ShipTemplatBased
    spaceObject.setHailText = function(self, hailText)
        if not isString(hailText) and not isNil(hailText) and not isFunction(hailText) then
            error("hailText needs to be a string or a function", 2)
        end
        theHailText = hailText

        return self
    end

    --- add a comms item
    --- @param self
    --- @param reply CommsReply
    --- @param id string (optional)
    --- @return string the id of this item
    spaceObject.addComms = function(self, reply, id)
        if not Comms:isReply(reply) then error("Expected reply to be a reply, but got " .. typeInspect(reply), 2) end
        id = id or Util.randomUuid()
        if not isString(id) then error("Expected id to be a string, but got " .. typeInspect(id), 2) end

        comms[id] = reply

        return id
    end

    --- remove a comms item
    --- @param self
    --- @param id string
    --- @return ShipTemplateBased
    spaceObject.removeComms = function(self, id)
        if not isString(id) then error("Expected id to be a string, but got " .. typeInspect(id), 2) end
        comms[id] = nil
        return self
    end

    --- get the comms screen to display
    --- @internal
    --- @param self
    --- @param player PlayerSpaceship
    --- @return CommsScreen
    spaceObject.getComms = function(self, player)
        if not isEePlayer(player) then error("Expected a Player, but got " .. typeInspect(player), 2) end
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
                    logWarning("Expected hail text function to return a string or nil, but got " .. typeInspect(hailText), 2)
                    hailText = nil
                end
            end
            return Comms.screen(hailText, howPlayerCanReact)
        end
    end

    --- temporarily override comms
    --- @param self
    --- @param screen CommsScreen
    --- @param once boolean (default: `false`)
    --- @return ShipTemplateBased
    spaceObject.overrideComms = function(self, screen, once)
        if not Comms:isScreen(screen) and not isNil(screen) then error("Expected a screen, but got " .. typeInspect(screen), 2) end
        once = once or false
        if not isBoolean(once) then error("Expected a boolean, but got " .. typeInspect(once), 2) end

        overriddenComms = screen
        overriddenCommsOnce = once

        return self
    end

    spaceObject:setCommsScript("lively_epsilon/src/scripts/comms.lua")

    if not isNil(config.hailText) then
        spaceObject:setHailText(config.hailText)
    end

    if isTable(config.comms) then
        for id,comms in pairs(config.comms) do
            if isNumber(id) then id = nil end
            spaceObject:addComms(comms, id)
        end
    elseif not isNil(config.comms) then
        error("Expected comms to be a table of comms, but got " .. typeInspect(config.comms), 2)
    end

    return spaceObject
end

--- check if the given thing has comms
--- @param self
--- @param thing any
--- @return boolean
ShipTemplateBased.hasComms = function(self, thing)
    return isFunction(thing.setHailText) and
            isFunction(thing.addComms) and
            isFunction(thing.removeComms) and
            isFunction(thing.getComms) and
            isFunction(thing.overrideComms)
end