Player = Player or {}

--- add an upgrade tracker to the ship
--- @param self
--- @param player PlayerSpaceship
--- @return PlayerSpaceship
Player.withUpgradeTracker = function(self, player)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if Player:hasUpgradeTracker(player) then error("Player " .. player:getCallSign() .. " already has a upgrade tracker", 2) end
    local upgrades = {}

    --- add an upgrade to the tracker
    --- @param self
    --- @param upgrade Upgrade
    --- @return PlayerSpaceship
    player.addUpgrade = function(self, upgrade)
        if not BrokerUpgrade:isUpgrade(upgrade) then error("Expected upgrade to be an Upgrade, but got " .. typeInspect(upgrade)) end
        upgrades[upgrade:getId()] = upgrade

        return self
    end

    --- check if the player have an upgrade installed
    --- @param self
    --- @param upgrade Upgrade|string
    --- @return boolean
    player.hasUpgrade = function(self, upgrade)
        if BrokerUpgrade:isUpgrade(upgrade) then
            upgrade = upgrade:getId()
        end
        if not isString(upgrade) then error("Expected upgrade to be an upgrade or an id, but got " .. typeInspect(upgrade), 2) end

        return upgrades[upgrade] ~= nil
    end

    --- get all installed upgrades
    --- @param self
    --- @return table[Upgrade]
    player.getUpgrades = function(self)
        local ret = {}
        for _, upgrade in pairs(upgrades) do
            table.insert(ret, upgrade)
        end
        return ret
    end
end

--- check if the player has an UpgradeTracker
--- @param self
--- @param player PlayerSpaceship
--- @return boolean
Player.hasUpgradeTracker = function(self, player)
    return isTable(player) and
            isFunction(player.addUpgrade) and
            isFunction(player.hasUpgrade) and
            isFunction(player.getUpgrades)
end