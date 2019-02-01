Comms = Comms or {}

Comms.upgradeBrokerFactory = function(self, config)
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    if not isString(config.label) and not isFunction(config.label) then error("expected label to be a string or function, but got " .. typeInspect(config.label), 2) end
    if not isFunction(config.mainScreen) then error("expected mainScreen to be a function, but got " .. typeInspect(config.mainScreen), 2) end
    if not isFunction(config.detailScreen) then error("expected detailScreen to be a function, but got " .. typeInspect(config.detailScreen), 2) end
    if not isFunction(config.installScreen) then error("expected installScreen to be a function, but got " .. typeInspect(config.installScreen), 2) end
    if not isNil(config.displayCondition) and not isFunction(config.displayCondition) then error("expected displayCondition to be a function, but got " .. typeInspect(config.displayCondition), 2) end

    local mainMenu
    local detailMenu
    local installMenu

    local defaultCallbackConfig

    local formatUpgrade = function(upgrade, station, player)
        local price = upgrade:getPrice()
        return {
            upgrade = upgrade,
            price = price,
            isAffordable = player:getReputationPoints() >= price,
            link = detailMenu(upgrade),
            linkInstall = installMenu(upgrade),
        }
    end

    local formatUpgrades = function(station, player)
        local ret = {}
        for _, upgrade in pairs(station:getUpgrades()) do
            if upgrade:canBeInstalled(player) then
                ret[upgrade:getId()] = formatUpgrade(upgrade, station, player)
            end
        end
        return ret
    end

    mainMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config:mainScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            upgrades = formatUpgrades(comms_target, comms_source),
        }))
        return screen
    end

    detailMenu = function(upgrade)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            config:detailScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, formatUpgrade(upgrade, comms_target, comms_source)))
            return screen
        end
    end

    installMenu = function(upgrade)
        return function(comms_target, comms_source)
            local upgradeInfo = formatUpgrade(upgrade, comms_target, comms_source)
            local screen = Comms.screen()
            local success = config:installScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, upgradeInfo))
            if not upgrade:canBeInstalled(comms_source) then
                if success == true then
                    logWarning("The upgrade " .. upgrade:getId() .. " can not be installed. This seems to be a problem with your comms screen.")
                end
                success = false
            elseif success == nil then
                logWarning("installScreen() should reply with true or false, but it replied with nil. Assuming 'true'.")
                success = true
            end
            if success == true then
                upgrade:install(comms_source)
            end
            return screen
        end
    end


    -- don't ask me why, but if this is defined with its declaration it will be an empty table in the callbacks...
    defaultCallbackConfig = {
        linkToMainScreen = mainMenu,
    }

    return Comms.reply(config.label, mainMenu, function(comms_target, comms_source)
        if not Station:hasUpgradeBroker(comms_target) then
            logInfo("not displaying upgrade_broker in Comms, because target has no upgrade_broker.")
            return false
        elseif userCallback(config.displayCondition, self, comms_target, comms_source) == false then
            return false
        end
        return true
    end)
end
