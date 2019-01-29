Player = Player or {}

-- config
-- - label
-- - title
-- - noUpgrades
Player.withUpgradeDisplay = function(self, player, config)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if not Player:hasUpgradeTracker(player) then error("Player " .. player:getCallSign() .. " should have a upgrade tracker", 2) end
    if not Player:hasMenu(player) then error("Expected player " .. player:getCallSign() .. " to have menus enabled, but it does not", 2) end
    if Player:hasUpgradeDisplay(player) then error("Player " .. player:getCallSign() .. " already has a upgrade display", 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    if not isString(config.label) then error("Expected label to be a string, but got " .. typeInspect(config.label), 2) end
    if not isString(config.title) then error("Expected title to be a string, but got " .. typeInspect(config.title), 2) end
    if not isString(config.noUpgrades) then error("Expected noUpgrades to be a string, but got " .. typeInspect(config.noUpgrades), 2) end

    -- The integration will probably change, because I think having some kind of menu structure might be the better option
    -- And it should be possible to translate or modify this. :)

    player:addEngineeringMenuItem(Menu:newItem(config.label, function()
        local text = config.title .. "\n--------------------------\n"

        local upgrades = {}
        for _, upgrade in pairs(player:getUpgrades()) do
            if BrokerUpgrade:isUpgrade(upgrade) then
                table.insert(upgrades, upgrade)
            end
        end

        if Util.size(upgrades) == 0 then
            text = text .. config.noUpgrades .. "\n"
        else
            for _, upgrade in pairs(upgrades) do
                text = text .. " * ".. upgrade:getName() .. "\n"
            end
        end

        return text
    end))

    player.upgradeDisplayActive = true
end

Player.hasUpgradeDisplay = function(self, player)
    return player.upgradeDisplayActive
end