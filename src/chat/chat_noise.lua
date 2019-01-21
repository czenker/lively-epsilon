Chatter = Chatter or {}

local find
-- returns nil or a table of valid shipTemplateBaseds
find = function(factory, found, others)
    local cardinality = factory:getCardinality()
    local foundCount = Util.size(found)

    for _,candidate in pairs(others) do
        local areValidArguments
        if foundCount == 0 then
            areValidArguments = factory:areValidArguments(candidate)
        else
            areValidArguments = factory:areValidArguments(table.unpack(found), candidate)
        end

        if areValidArguments then
            local newFound = {}
            for k,v in ipairs(found) do
                newFound[k] = v
            end
            table.insert(newFound, candidate)

            if cardinality == foundCount + 1 then
                -- if this is the last item
                return newFound
            else
                local newOthers = {}
                for _,v in pairs(others) do
                    if v ~= candidate then
                        table.insert(newOthers, v)
                    end
                end
                local ret = find(factory, newFound, newOthers)
                if ret ~= nil then
                    return ret
                end
            end
        end
    end

    return nil
end


local findParameters = function(factory, shipTemplateBaseds)
    if factory:getCardinality() > Util.size(shipTemplateBaseds) then
        logDebug("Not considering factory for ChatNoise, because cardinality " .. factory:getCardinality() .. " is bigger than number of ships in the vicinity.")
        return nil
    end

    return find(factory, {}, shipTemplateBaseds)
end

-- a randomizer that generates chats between ships and stations
Chatter.newNoise = function(self, chatter, config)
    if not Chatter:isChatter(chatter) then error("Expected chatter to be a Chatter, but got " .. typeInspect(chatter), 2) end

    config = config or {}
    if not isTable(config) then error("Config needs to be a table, but " .. type(config) .. " given", 2) end

    local cronId = "chatter-" .. Util.randomUuid()
    local delay = 60
    local range = getLongRangeRadarRange()

    local factories = {}
    local factoryKeys = {}

    local doit = function()
        if Util.size(factories) == 0 then
            logInfo("Not running ChatNoise " .. cronId .. ", because no Chat Factories have been added.")
            return
        end

        local player = getPlayerShip(-1)
        if player == nil or player:isValid() == false then
            logInfo("Not running ChatNoise " .. cronId .. ", because player is not valid.")
        end

        local shipTemplateBaseds = {}

        for _,v in pairs(player:getObjectsInRange(range)) do
            if isEeShipTemplateBased(v) and not isEePlayer(v) and v:isValid() then
                table.insert(shipTemplateBaseds, v)
            end
        end

        if Util.size(shipTemplateBaseds) == 0 then
            logInfo("Not running ChatNoise " .. cronId .. ", because there is no one in range of " .. player:getCallSign())
            return
        end

        shipTemplateBaseds = Util.randomSort(shipTemplateBaseds)

        for _,factoryKey in pairs(Util.randomSort(factoryKeys)) do
            local factory = factories[factoryKey]

            local arguments = findParameters(factory, shipTemplateBaseds)

            if arguments ~= nil then
                logDebug("Running Chat " .. factoryKey .. " with " .. Util.mkString(Util.map(arguments, function(v) return v:getCallSign() end), ", ", " and ") .. ".")

                local chat = factory:createChat(table.unpack(arguments))
                chatter:converse(chat)
                return
            end
        end

        logWarning("Did not find a suitable chat for ChatNoise " .. cronId)
    end

    Cron.regular(cronId, doit, delay, delay)

    return {
        addChatFactory = function(_, chatFactory, id)
            if not Chatter:isChatFactory(chatFactory) then error("Expected chatFactory, but got " .. typeInspect(chatFactory)) end
            id = id or Util.randomUuid()
            if not isString(id) or id == "" then error("Expected id to be a non-empty string, but got " .. typeInspect(id)) end

            factoryKeys[id] = id
            factories[id] = chatFactory

            return id
        end,
        removeChatFactory = function(_, id)
            if not isString(id) or id == "" then error("Expected id to be a non-empty string, but got " .. typeInspect(id)) end
            factories[id] = nil
            factoryKeys[id] = nil
        end,
    }

end

Chatter.isChatNoise = function(self, thing)
    return isTable(thing) and
            isFunction(thing.addChatFactory) and
            isFunction(thing.removeChatFactory)
end
