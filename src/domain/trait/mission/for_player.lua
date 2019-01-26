Mission = Mission or {}

Mission.forPlayer = function(self, mission, initPlayer)
    if not Mission:isMission(mission) then error("Expected mission to be a Mission, but " .. typeInspect(mission) .. " given.", 2) end
    if mission:getState() ~= "new" then error("The mission must not be started yet, but got " .. typeInspect(mission:getState()), 2) end
    if Mission:isPlayerMission(mission) then error("The given mission is already a PlayerMission.", 2) end

    -- the player who has accepted or wants to accept the mission
    local player
    local parentAccept = mission.accept

    ---mark the mission as accepted. `setPlayer` needs to have been called beforehand.
    ---@param self
    mission.accept = function(self)
        if player == nil then error("The player needs to be set before calling accept", 2) end
        return parentAccept(self)
    end

    local parentStart = mission.start
    ---mark the mission as started
    ---@param self
    mission.start = function(self)
        parentStart(self)

        Cron.regular(function(self)
            if mission:getState() ~= "started" then
                Cron.abort(self)
            elseif not mission:getPlayer() or not mission:getPlayer():isValid() then
                mission:fail()
                Cron.abort(self)
            end
        end, 0.1)
    end

    ---Set the player that does the mission
    ---@param self
    ---@param thing PlayerSpaceship
    mission.setPlayer = function(self, thing)
        if not isEePlayer(thing) then error("Expected player to be a Player, but " .. typeInspect(thing) .. " given.", 2) end
        player = thing
    end

    ---get the player that does the mission
    ---@param self
    mission.getPlayer = function(self)
        return player
    end

    if isEePlayer(initPlayer) then
        mission:setPlayer(initPlayer)
    end
end

Mission.isPlayerMission = function(self, thing)
    return Mission:isMission(thing) and
            isFunction(thing.getPlayer) and
            isFunction(thing.setPlayer)
end