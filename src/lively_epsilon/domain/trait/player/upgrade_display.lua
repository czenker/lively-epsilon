Player = Player or {}

Player.withUpgradeDisplay = function(self, player)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. type(player), 2) end
    if not Player:hasUpgradeTracker(player) then error("Player should have a upgrade tracker" .. type(player), 2) end
    if Player:hasUpgradeDisplay(player) then error("Player already has a upgrade display" .. type(player), 2) end

    -- The integration will probably change, because I think having some kind of menu structure might be the better option
    -- And it should be possible to translate or modify this. :)

    local buttonId = "upgrade_display"
    local buttonLabel = "Upgrades"
    local crewPosition = "engineering"

    player:addCustomButton(crewPosition, buttonId, buttonLabel, function()
        local upgrades = {}
        for _, upgrade in pairs(player:getUpgrades()) do
            if Upgrade:isBrokerUpgrade(upgrade) then
                table.insert(upgrades, upgrade)
            end
        end
        local text = buttonLabel .. "\n\n"

        if Util.size(upgrades) == 0 then
            text = text .. "You currently have no upgrades installed."
        else
            for _, upgrade in pairs(upgrades) do
                text = text .. " * ".. upgrade:getName() .. "\n"
            end
        end

        player:addCustomMessage(crewPosition, buttonLabel, text)
    end)

    player.upgradeDisplayActive = true
end

Player.hasUpgradeDisplay = function(self, player)
    return player.upgradeDisplayActive
end