Player = Player or {}

Player.withMissionTracker = function(self, player)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if Player:hasMissionTracker(player) then error("Player " .. player:getCallSign() .. " already has a mission tracker", 2) end
    local missions = {}

    player.addMission = function(self, mission)
        if not Mission:isMission(mission) then error("Expected mission to be a Mission, but got " .. typeInspect(mission)) end
        missions[mission:getId()] = mission
    end

    player.getStartedMissions = function(self)
        local ret = {}
        for _, mission in pairs(missions) do
            if mission:getState() == "started" then
                table.insert(ret, mission)
            end
        end
        return ret
    end

    -- @TODO: filter for other mission states
end

Player.hasMissionTracker = function(self, player)
    return isFunction(player.addMission) and
            isFunction(player.getStartedMissions)

end