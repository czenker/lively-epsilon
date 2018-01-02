MyMission = MyMission or {}

-- Bring something or someone from one station to another

MyMission.transportToken = function(self, from, to)
    if not isEeStation(from) then error("from needs to be a Station, " .. type(from) .. " given.") end
    if not isEeStation(to) then error("to needs to be a Station, " .. type(to) .. " given.") end
    if not isEePlayer(player) then error("player needs to be a Player, " .. type(player) .. " given.") end

    local isLoaded = false
    local cronId = Util.randomUuid()
    local title = "Transport from " .. from:getCallSign() .. " to " .. to:getCallSign() .. "."

    local mission
    mission = Mission:new(title, {
        onStart = function(self)
            Cron.regular(cronId, function()
                if isLoaded == false and player:isDocked(from) then
                    print("PlayerShip loaded")
                    isLoaded = true
                end
                if isLoaded == true and player:isDocked(to) then
                    print("PlayerShip unloaded")
                    isLoaded = false
                    self:success()
                end
            end, 0.5)
        end,
        onSuccess = function() end,
        onFailure = function() end,
        onEnd = function()
            Cron.abort(cronId)
        end,
    })

    Mission:withAcceptDialog(mission,
        "It is very important that the Red Herrings are shipped without harming them. We can't offer payment at the moment, but the feeling of having done a good deed should be enough of a reward.", {
        acceptLabel = "Accept",
        acceptResponse = "Thanks for taking care of this transport mission. We brought the cargo to your ships storage already.",
        declineLabel = "Decline",
    })

    return mission
end