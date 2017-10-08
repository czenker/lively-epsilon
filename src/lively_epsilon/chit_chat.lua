-- ChitChat is the radio noise that the universe is filled with
--
-- There are ships flying by each other conversing about docking,
-- chatting about the space weather and much more. They fill the world
-- with live and makes them human (or whatever race they are).
-- ChitChat writes these conversations to the players log so they
-- can be read by the Relay Officer.
--
-- Here is how to use it:
--
--  ChitChat.say("DS1", "Hello World")
--  ChitChat.say(SpaceStation():setFaction("Human Navy"), "Hello World")
--
--  ship = CpuShip()
--  station = SpaceStation()
--  ChitChat.converse({
--    {ship, "Hello, Station"},
--    {station, "Hello yourself, Ship"}
--  })
--
--
-- Ideas for improvement (@TODO):
--   - color logs according to friend or foe
--   - send logs to all ships
--   - only send logs if the player is close enough to the sender

local function send(message)
    getPlayerShip(1):addToShipLog(message, "128,128,128")
end

local function sendFromString(sender, message)
    send(sender .. ": " .. message)
end

local function sendFromEeObject(thing, message)
    local sender = thing:getCallSign()
    if thing.captain ~= nil then
        sender = thing.captain:name() .. " (" .. sender .. ")"
    end

    sendFromString(sender, message)
end

-- calculates the delay that you typically need to read the message
local function calculateDelay(message)
    local wordsPerMinute = 120
    local numberOfWords = string.len(string.gsub(message, "%S", "")) + 1

    return numberOfWords / wordsPerMinute * 60 + 0.5
end

ChitChat = {
    say = function(sender, message)
        if isEeShip(sender) or isEeStation(sender) then
            sendFromEeObject(sender, message)
        elseif type(sender) == "string" then
            sendFromString(sender, message)
        else
            error("ChitChat.say called with invalid sender parameter. Got " .. type(sender), 2)
        end
    end,

    converse = function(messages)
        local entry = table.remove(messages, 1)
        ChitChat.say(entry[1], entry[2])

        if Util.size(messages) > 0 then
            Cron.once(
                function() ChitChat.converse(messages) end,
                calculateDelay(entry[2])
            )
        end
    end
}