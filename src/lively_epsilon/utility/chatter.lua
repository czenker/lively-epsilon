Chatter = Chatter or {}

-- calculates the delay that you typically need to read the message
local function calculateDelay(message)
    local wordsPerMinute = 120
    local numberOfWords = string.len(string.gsub(message, "%S", "")) + 1

    return numberOfWords / wordsPerMinute * 60
end

local function send(sender, message)
    local i = 1
    local player = getPlayerShip(i)

    while player ~= nil do
        player:addToShipLog(sender .. ": " .. message, "128,128,128")

        i = i+1
        player = getPlayerShip(i)
    end
end

local function conversation(messages)
    local sender, message = table.unpack(table.remove(messages, 1))
    if isEeShipTemplateBased(sender) then
        if sender:isValid() then
            sender = sender:getCallSign()
        else
            logWarning("Stopping conversation because sender is destroyed.")
            return
        end
    end

    if messages[1] ~= nil then
        Cron.once(function() conversation(messages) end, calculateDelay(message))
    end

    send(sender, message)
end

Chatter.new = function()
    local self = {}

    self.say = function(_, sender, message)
        if isEeShipTemplateBased(sender) then
            if sender:isValid() then
                sender = sender:getCallSign()
            else
                logWarning("Not sending chat because sender is destroyed.")
                return
            end
        end
        if not isString(sender) then error("Sender needs to be a shipTemplateBased or a string, but got " .. type(sender), 2) end
        if not isString(message) then error("Message needs to be a string, but got " .. type(message), 2) end

        send(sender, message)

    end
    self.converse = function(_, messages)
        if not isTable(messages) then error("Expected messages to be a numeric table, but got " .. type(messages), 2) end
        if not Util.isNumericTable(messages) then error("Expected messages to be a numeric table, but got an associative one. This is problematic because such a table does not guarantee the order of its contained elements. Create a table with numeric indices instead.", 2) end
        if messages[1] == nil then
            logWarning("Sending a conversation without any lines looks fishy")
        else
            for i, value in ipairs(messages) do
                if not isTable(value) then error("Expected all messages to be a table, but got " .. type(value) .. " at position " .. i, 2) end
                local size = Util.size(value)
                if size < 2 then error("Expected all messages to have two fields, but got " .. size .. " at position " .. i, 2) end
                if size > 2 then logWarning("Expected all message to have two fields, but got " .. size .. " at position " .. i .. ". Will ignore any additionals.") end

                local sender, message = table.unpack(value)
                if not isEeShipTemplateBased(sender) and not isString(sender) then error("Expected all senders to be shipTemplateBased or string, but got " .. type(sender) .. " at position " .. i, 2) end
                if not isString(message) then error("Expected all messages to be strings, but got " .. type(message) .. " at position " .. i, 2) end
            end

            conversation(messages)
        end
    end

    return self
end