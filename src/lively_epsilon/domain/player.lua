local prototype = {
    isEnriched = true,
    setMission = function(self, mission)
        -- stop the old mission
        if self.mission ~= nil then
            if type(self.mission.stop) == "function" then
                self.mission:stop()
            end
        end

        self.missionStarted = false
        self.mission = mission
    end,
    logMission = function(self, message)
        self:addToShipLog(message, "0,255,255")
    end
}

Player = Player or {}

-- enrich a PlayerSpaceship with more story driven properties
Player.enrich = function(self, player)
    if not isEePlayer(player) then
        error("player given to Player.enrich needs to be a PlayerSpaceship", 2)
    end

    if (player.isEnriched == true) then return player end

    for key, value in pairs(prototype) do
        player[key] = value
    end

    Cron.regular("startMission" .. player:getCallSign(), function()
        if player.mission ~= nil and player.missionStarted == false then
            print("starting mission '" .. player.mission.title .. "'")
            player.mission:start(player)
            player.missionStarted = true
        end
    end, 0.5)

    return player
end
