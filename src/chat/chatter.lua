Chatter = Chatter or {}

-- calculates the delay that you typically need to read the message
local function calculateDelay(message)
    local wordsPerMinute = 120
    local numberOfWords = string.len(string.gsub(message, "%S", "")) + 1

    return numberOfWords / wordsPerMinute * 60
end

--- Chatter is a module to handle random messages flying through space.
--- Usually they come from nearby ships and stations and the comms officer is able to monitor them.
---
--- @param self
--- @param config table
---    @field maxRange number (default: `PlayerSpaceship:getLongRangeRadarRange() * 1.5`) the maximum range the player receives chats from their surrounding.
Chatter.new = function(self, config)
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    local maxRange = config.maxRange
    if not isNumber(maxRange) and not isNil(maxRange) then error("maxRange needs to be a number or nil, but got " .. typeInspect(config.maxRange), 2) end

    local function send(sender, message)
        local senderName
        local i = 1
        local player = getPlayerShip(i)

        if isEeShipTemplateBased(sender) then
            if sender:isValid() then
                senderName = sender:getCallSign()
            else
                return false
            end
        else
            senderName = sender
            sender = nil
        end

        while player ~= nil do
            local playerRange = maxRange or player:getLongRangeRadarRange() * 1.5
            if sender == nil or distance(player, sender) < playerRange then
                player:addToShipLog(senderName .. ": " .. message, "128,128,128")
            end

            i = i+1
            player = getPlayerShip(i)
        end

        return true
    end

    local conversation
    conversation = function(messages)
        local sender, message = table.unpack(table.remove(messages, 1))

        if not send(sender, message) then
            logWarning("Stopping conversation because sender is destroyed.")
        else
            if messages[1] ~= nil then
                Cron.once(function() conversation(messages) end, calculateDelay(message))
            end
        end
    end

    local chatter = {}

    --- send a single message
    --- @param self
    --- @param sender ShipTemplateBased
    --- @param message string
    chatter.say = function(self, sender, message)
        if not isEeShipTemplateBased(sender) and not isString(sender) then error("Sender needs to be a shipTemplateBased or a string, but got " .. typeInspect(sender), 2) end
        if not isString(message) then error("Message needs to be a string, but got " .. typeInspect(message), 2) end

        if not send(sender, message) then
            logWarning("Not sending chat because sender is destroyed.")
        end
    end
    --- start a conversation
    --- @param self
    --- @param messages table
    chatter.converse = function(self, messages)
        if not isTable(messages) then error("Expected messages to be a numeric table, but got " .. typeInspect(messages), 2) end
        if not Util.isNumericTable(messages) then error("Expected messages to be a numeric table, but got an associative one. This is problematic because such a table does not guarantee the order of its contained elements. Create a table with numeric indices instead.", 2) end
        if messages[1] == nil then
            logWarning("Sending a conversation without any lines looks fishy")
        else
            for i, value in ipairs(messages) do
                if not isTable(value) then error("Expected all messages to be a table, but got " .. typeInspect(value) .. " at position " .. i, 2) end
                local size = Util.size(value)
                if size < 2 then error("Expected all messages to have two fields, but got " .. size .. " at position " .. i, 2) end
                if size > 2 then logWarning("Expected all message to have two fields, but got " .. size .. " at position " .. i .. ". Will ignore any additionals.") end

                local sender, message = table.unpack(value)
                if not isEeShipTemplateBased(sender) and not isString(sender) then error("Expected all senders to be shipTemplateBased or string, but got " .. typeInspect(sender) .. " at position " .. i, 2) end
                if not isString(message) then error("Expected all messages to be strings, but got " .. typeInspect(message) .. " at position " .. i, 2) end
            end

            conversation(messages)
        end
    end

    return chatter
end

--- check if the given thing is a valid Chatter
--- @param self
--- @param thing any
--- @return boolean
Chatter.isChatter = function(self, thing)
    return isTable(thing) and
            isFunction(thing.say) and
            isFunction(thing.converse)
end