Chatter = Chatter or {}

-- track the last 10 used factory keys
local lastUsedFactoryKeysSize = 10

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

--- a randomizer that generates chats between ships and stations
--- @param self
--- @param chatter Chatter
--- @param config table
--- @return ChatterNoise
Chatter.newNoise = function(self, chatter, config)
    if not Chatter:isChatter(chatter) then error("Expected chatter to be a Chatter, but got " .. typeInspect(chatter), 2) end

    config = config or {}
    if not isTable(config) then error("Config needs to be a table, but " .. typeInspect(config) .. " given", 2) end

    local cronId = "chatter-" .. Util.randomUuid()
    local delay = 60

    local factories = {}
    local factoryKeys = {}
    local lastUsedFactoryKeys = {}

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

        for _,v in pairs(player:getObjectsInRange(player:getLongRangeRadarRange())) do
            if isEeShipTemplateBased(v) and not isEePlayer(v) and v:isValid() then
                table.insert(shipTemplateBaseds, v)
            end
        end

        if Util.size(shipTemplateBaseds) == 0 then
            logInfo("Not running ChatNoise " .. cronId .. ", because there is no one in range of " .. player:getCallSign())
            return
        end

        shipTemplateBaseds = Util.randomSort(shipTemplateBaseds)

        local keys = Util.randomSort(factoryKeys)

        -- prevent repetition of chats
        local malusByKey = {}
        for i=1,lastUsedFactoryKeysSize do
            local key = lastUsedFactoryKeys[i]
            if key ~= nil then
                malusByKey[key] = (malusByKey[key] or 0) + (lastUsedFactoryKeysSize - i + 1)
            end
        end

        table.sort(keys, function(keyA, keyB)
            return (malusByKey[keyA] or 0) < (malusByKey[keyB] or 0)
        end)

        for _,factoryKey in pairs(keys) do
            local factory = factories[factoryKey]

            local arguments = findParameters(factory, shipTemplateBaseds)

            if arguments ~= nil then
                logDebug("Running Chat " .. factoryKey .. " with " .. Util.mkString(Util.map(arguments, function(v) return v:getCallSign() end), ", ", " and ") .. ".")

                table.insert(lastUsedFactoryKeys, 1, factoryKey)
                lastUsedFactoryKeys[10] = nil

                local chat = factory:createChat(table.unpack(arguments))
                chatter:converse(chat)
                return
            end
        end

        logWarning("Did not find a suitable chat for ChatNoise " .. cronId)
    end

    Cron.regular(cronId, doit, delay, delay)

    return {
        --- add a chat factory
        --- @param self
        --- @param chatFactory ChatFactory
        --- @param id string (optional)
        --- @return string the id of this chat factory
        addChatFactory = function(self, chatFactory, id)
            if not Chatter:isChatFactory(chatFactory) then error("Expected chatFactory, but got " .. typeInspect(chatFactory)) end
            id = id or Util.randomUuid()
            if not isString(id) or id == "" then error("Expected id to be a non-empty string, but got " .. typeInspect(id)) end

            factoryKeys[id] = id
            factories[id] = chatFactory

            return id
        end,
        --- @param self
        --- @param id string
        removeChatFactory = function(self, id)
            if not isString(id) or id == "" then error("Expected id to be a non-empty string, but got " .. typeInspect(id)) end
            factories[id] = nil
            factoryKeys[id] = nil
        end,
        --- return all chat factories
        --- @param self
        --- @return table[string,ChatFactory]
        getChatFactories = function(self)
            -- make a copy to make it deletable while being traversable and prevent it from being manipulated
            local facts = {}

            for _, key in pairs(factoryKeys) do
                facts[key] = factories[key]
            end

            return facts
        end,
    }

end

--- check if the given thing is a valid ChatNoise
--- @param self
--- @param thing any
--- @return boolean
Chatter.isChatNoise = function(self, thing)
    return isTable(thing) and
            isFunction(thing.addChatFactory) and
            isFunction(thing.removeChatFactory) and
            isFunction(thing.getChatFactories)
end
