Player = Player or {}

Player.withMissionDisplay = function(self, player)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. type(player), 2) end
    if not Player:hasMissionTracker(player) then error("Player should have a mission tracker" .. type(player), 2) end
    if Player:hasMissionDisplay(player) then error("Player already has a mission display" .. type(player), 2) end

    -- The integration will probably change, because I think having some kind of menu structure might be the better option
    -- And it should be possible to translate or modify this. :)

    local buttonId = "mission_display"
    local buttonLabel = "Missions"

    player:addCustomButton("relay", buttonId, buttonLabel, function()
        local missions = {}
        for _, mission in pairs(player:getStartedMissions()) do
            if Mission.isBrokerMission(mission) then
                table.insert(missions, mission)
            end
        end
        local text = buttonLabel .. "\n\n"

        if Util.size(missions) == 0 then
            text = text .. "You currently have no active missions."
        else
            for _, mission in pairs(missions) do
                text = text .. " * ".. mission:getTitle() .. "\n"
            end
        end

        player:addCustomMessage("relay", buttonLabel, text)
    end)

    player.missionDisplayActive = true

end

Player.hasMissionDisplay = function(self, player)
    return player.missionDisplayActive
end