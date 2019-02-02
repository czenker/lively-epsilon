Player = Player or {}

--- tracks the active missions of the player
--- @param self
--- @param player PlayerSpaceship
--- @return PlayerSpaceship
Player.withMissionTracker = function(self, player)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if Player:hasMissionTracker(player) then error("Player " .. player:getCallSign() .. " already has a mission tracker", 2) end
    local missions = {}

    --- add a mission to the mission tracker
    --- @param self
    --- @param mission Mission
    --- @return PlayerSpaceship
    player.addMission = function(self, mission)
        if not Mission:isMission(mission) then error("Expected mission to be a Mission, but got " .. typeInspect(mission)) end
        missions[mission:getId()] = mission
        return self
    end

    --- get all the started missions
    --- @param self
    --- @return table[Mission]
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

    return player
end

--- check if the player has a MissionTracker
--- @param self
--- @param player PlayerSpaceship
--- @return boolean
Player.hasMissionTracker = function(self, player)
    return isTable(player) and
            isFunction(player.addMission) and
            isFunction(player.getStartedMissions)

end