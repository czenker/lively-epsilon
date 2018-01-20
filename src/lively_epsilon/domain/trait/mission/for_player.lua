Mission = Mission or {}

Mission.forPlayer = function(self, mission, initPlayer)
    if not Mission.isMission(mission) then error("Expected mission to be a Mission, but " .. type(mission) .. " given.", 2) end
    if Mission.isPlayerMission(mission) then error("The given mission is already a PlayerMission.", 2) end

    -- the player who has accepted or wants to accept the mission
    local player
    local parentAccept = mission.accept

    mission.accept = function(self)
        if player == nil then error("The player needs to be set before calling accept", 2) end
        return parentAccept(self)
    end

    mission.setPlayer = function(self, thing)
        if not isEePlayer(thing) then error("Expected player to be a Player, but " .. type(thing) .. " given.", 2) end
        player = thing
    end

    mission.getPlayer = function(self)
        return player
    end

    if isEePlayer(initPlayer) then
        mission:setPlayer(initPlayer)
    end
end

Mission.isPlayerMission = function(thing)
    return Mission.isMission(thing) and
            isFunction(thing.getPlayer) and
            isFunction(thing.setPlayer)
end