Player = Player or {}

Player.withUpgradeTracker = function(self, player)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if Player:hasUpgradeTracker(player) then error("Player already has a upgrade tracker" .. type(player), 2) end
    local upgrades = {}

    player.addUpgrade = function(self, upgrade)
        if not BrokerUpgrade:isUpgrade(upgrade) then error("Expected upgrade to be an Upgrade, but got " .. typeInspect(upgrade)) end
        upgrades[upgrade:getId()] = upgrade
    end

    player.hasUpgrade = function(self, upgrade)
        if BrokerUpgrade:isUpgrade(upgrade) then
            upgrade = upgrade:getId()
        end
        if not isString(upgrade) then error("Expected upgrade to be an upgrade or an id, but got " .. typeInspect(upgrade), 2) end

        return upgrades[upgrade] ~= nil
    end

    player.getUpgrades = function(self)
        local ret = {}
        for _, upgrade in pairs(upgrades) do
            table.insert(ret, upgrade)
        end
        return ret
    end
end

Player.hasUpgradeTracker = function(self, player)
    return isFunction(player.addUpgrade) and
            isFunction(player.hasUpgrade) and
            isFunction(player.getUpgrades)
end