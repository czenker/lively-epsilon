Player = Player or {}

-- config
-- - label
-- - titleActiveMissions
-- - noActiveMissions
Player.withMissionDisplay = function(self, player, config)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. type(player), 2) end
    if not Player:hasMissionTracker(player) then error("Player should have a mission tracker" .. type(player), 2) end
    if not Player:hasMenu(player) then error("Expected player " .. player:getCallSign() .. " to have menus enabled, but it does not", 2) end
    if Player:hasMissionDisplay(player) then error("Player already has a mission display" .. type(player), 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    if not isString(config.label) then error("Expected label to be a string, but got " .. type(config.label), 2) end
    if not isString(config.titleActiveMissions) then error("Expected titleActiveMissions to be a string, but got " .. type(config.titleActiveMissions), 2) end
    if not isString(config.noActiveMissions) then error("Expected noActiveMissions to be a string, but got " .. type(config.noActiveMissions), 2) end

    -- The integration will probably change, because I think having some kind of menu structure might be the better option
    -- And it should be possible to translate or modify this. :)

    player:addRelayMenuItem(Menu:newItem(config.label, function()
        local text = config.titleActiveMissions .. "\n--------------------------\n"

        local missions = {}
        for _, mission in pairs(player:getStartedMissions()) do
            if Mission:isBrokerMission(mission) then
                table.insert(missions, mission)
            end
        end

        if Util.size(missions) == 0 then
            text = text .. config.noActiveMissions .. "\n"
        else
            for _, mission in pairs(missions) do
                text = text .. " * ".. mission:getTitle() .. "\n"
                if mission:getHint() then
                    text = text .. "        " .. mission:getHint() .. "\n"
                end
            end
        end

        return text
    end))

    player.missionDisplayActive = true

end

Player.hasMissionDisplay = function(self, player)
    return player.missionDisplayActive
end