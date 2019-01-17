BrokerUpgrade = BrokerUpgrade or {}

--
-- * name
-- * onInstall
-- * id
-- * description
-- * installMessage
-- * price
-- * unique
-- * requiredUpgrade
BrokerUpgrade = {
    new = function(self, config)
        config = config or {}
        if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
        local name = config.name
        if not isString(name) then error("Expected name to be a string, but got " .. type(name), 2) end
        local onInstall = config.onInstall or (function() end)
        if not isFunction(onInstall) then error("Expected onInstall routine to be a function, but got " .. type(onInstall), 2) end
        local id = config.id or Util.randomUuid()
        if not isString(id) then error("Expected id to be a string, but got " .. type(id), 2) end
        local description = config.description
        if not isNil(description) and not isString(description) and not isFunction(description) then error("Expected description to be string or function, but got " .. type(description), 2) end
        local installMessage = config.installMessage
        if not isNil(installMessage) and not isString(installMessage) and not isFunction(installMessage) then error("Expected installMessage to be string or function, but got " .. type(installMessage), 2) end
        local price = config.price or 0
        if not isNumber(price) then error("Expected price to be numeric, but got " .. type(price), 2) end
        local unique = config.unique or false
        if not isBoolean(unique) then error("Expected unique to be boolean, but got " .. type(unique), 2) end
        local requiredUpgrade = config.requiredUpgrade
        if not isNil(requiredUpgrade) and not isString(requiredUpgrade) and not BrokerUpgrade:isUpgrade(requiredUpgrade) then error("Expected requiredUpgrade to be an Upgrade or id, but got " .. type(requiredUpgrade), 2) end

        return {
            getId = function() return id end,
            getName = function() return name end,
            install = function(self, player)
                if not isEePlayer(player) then error("Expected player, but got " .. type(player), 2) end
                local success, msg = self:canBeInstalled(player)
                if not success then error("Upgrade " .. id .. " can not be installed, because requirement is not fulfilled: " .. (msg or "")) end

                onInstall(self, player)
                player:takeReputationPoints(self:getPrice(player))
                if Player:hasUpgradeTracker(player) then
                    player:addUpgrade(self)
                end
            end,
            getPrice = function(self, player) return price end,
            canBeInstalled = function(self, player)
                if not isEePlayer(player) then error("Expected player, but got " .. type(player), 2) end
                local success, msg = true, nil
                if isFunction(config.canBeInstalled) then
                    success, msg = config.canBeInstalled(self, player)
                    if isNil(success) then
                        logInfo("canBeInstalled returned nil as state, so true is assumed")
                        success = true
                    elseif not isBoolean(success) then
                        logWarning("canBeInstalled returned " .. type(success) .. "as success state, so true is assumed")
                        success = true
                    end
                    if success == true and not isNil(msg) then
                        logWarning("ignoring message on success in canBeInstalled")
                        msg = nil
                    elseif not isNil(msg) and not isString(msg) then
                        logWarning("expected message to be a string, but got " .. type(msg) .. ", asuming nil.")
                        msg = nil
                    end
                end
                if success == true and unique == true then
                    if not Player:hasUpgradeTracker(player) then
                        success, msg = false, "no_upgrade_tracker"
                    elseif player:hasUpgrade(self) then
                        success, msg = false, "unique"
                    end
                end
                if success == true and requiredUpgrade ~= nil then
                    if not Player:hasUpgradeTracker(player) then
                        success, msg = false, "no_upgrade_tracker"
                    elseif not player:hasUpgrade(requiredUpgrade) then
                        success, msg = false, "required_upgrade"
                    end
                end

                return success, msg
            end,
            getDescription = function(self, player)
                if not isEePlayer(player) then error("Expected player to be a player object, but got " .. type(player), 2) end
                if isFunction(description) then
                    return description(self)
                else
                    return description
                end
            end,
            getInstallMessage = function(self, player)
                if not isEePlayer(player) then error("Expected player to be a player object, but got " .. type(player), 2) end
                if isFunction(installMessage) then
                    return installMessage(self)
                else
                    return installMessage
                end
            end,
            getRequiredUpgradeString = function(self)
                return config.requiredUpgrade
            end,
        }
    end,
    isUpgrade = function(self, thing)
        return isTable(thing) and
                isFunction(thing.getId) and
                isFunction(thing.canBeInstalled) and
                isFunction(thing.install) and
                isFunction(thing.getName) and
                isFunction(thing.getPrice) and
                isFunction(thing.getDescription) and
                isFunction(thing.getInstallMessage) and
                isFunction(thing.getRequiredUpgradeString)
    end
}

setmetatable(BrokerUpgrade,{
    __index = Generic
})