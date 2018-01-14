Comms = Comms or {}

--- Generates a comms
Comms.commandFactory = function(self, config)
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    if not isString(config.label) and not isFunction(config.label) then error("expected label to be a string or function, but got " .. type(config.label), 2) end
    if not isFunction(config.commandScreen) then error("expected commandScreen to be a function, but got " .. type(config.commandScreen), 2) end
    if not isFunction(config.defendScreen) then error("expected defendScreen to be a function, but got " .. type(config.defendScreen), 2) end
    if not isFunction(config.defendConfirmScreen) then error("expected defendConfirmScreen to be a function, but got " .. type(config.defendConfirmScreen), 2) end
    if not isFunction(config.attackScreen) then error("expected attackScreen to be a function, but got " .. type(config.attackScreen), 2) end
    if not isFunction(config.attackConfirmScreen) then error("expected attackConfirmScreen to be a function, but got " .. type(config.attackConfirmScreen), 2) end
    if not isFunction(config.navigationScreen) then error("expected navigationScreen to be a function, but got " .. type(config.navigationScreen), 2) end
    if not isFunction(config.navigationConfirmScreen) then error("expected navigationConfirmScreen to be a function, but got " .. type(config.navigationConfirmScreen), 2) end

    local commandMenu
    local defendMenu
    local defendConfirmMenu
    local attackMenu
    local attackConfirmMenu
    local navigationMenu
    local navigationConfirmMenu

    local defaultCallbackConfig

    -- the main screen
    commandMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config:commandScreen(screen, comms_target, comms_source, defaultCallbackConfig)
        return screen
    end

    defendMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        local targets = {}

        if comms_source:getWaypointCount() > 0 then
            for i=1,comms_source:getWaypointCount() do
                local x, y = comms_source:getWaypoint(i)
                local target = {math.floor(x), math.floor(y)}
                table.insert(targets, {
                    target = target,
                    index = i,
                    link = defendConfirmMenu({target = target, index = i}),
                })
            end
        end

        for _,obj in pairs(comms_target:getObjectsInRange(getLongRangeRadarRange())) do
            if isEeStation(obj) and not comms_target:isEnemy(obj) then
                table.insert(targets, {
                    target = obj,
                    link = defendConfirmMenu({target = obj}),
                })
            end
        end

        config:defendScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            targets = targets,
        }))
        return screen
    end

    defendConfirmMenu = function(target)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            local success = config:defendConfirmScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, target))

            if success == nil then
                logWarning("defendConfirmScreen() should reply with true or false, but it replied with nil. Assuming 'true'.")
            end
            if success == true or success == nil then
                if isEeStation(target.target) then
                    comms_target:orderDefendTarget(target.target)
                elseif isVector2f(target.target) then
                    comms_target:orderDefendLocation(target.target[1], target.target[2])
                end
            end

            return screen
        end
    end

    attackMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        local targets = {}

        for _,obj in pairs(comms_target:getObjectsInRange(getLongRangeRadarRange())) do
            if isEeShipTemplateBased(obj) and comms_target:isEnemy(obj) then
                table.insert(targets, {
                    target = obj,
                    link = attackConfirmMenu({target = obj}),
                })
            end
        end

        config:attackScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            targets = targets,
        }))
        return screen
    end

    attackConfirmMenu = function(target)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            local success = config:attackConfirmScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, target))

            if success == nil then
                logWarning("attackConfirmScreen() should reply with true or false, but it replied with nil. Assuming 'true'.")
            end
            if success == nil or success == true then
                if isEeShipTemplateBased(target.target) then
                    comms_target:orderAttack(target.target)
                end
            end

            return screen
        end
    end

    navigationMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        local targets = {}

        if comms_source:getWaypointCount() > 0 then
            for i=1,comms_source:getWaypointCount() do
                local x, y = comms_source:getWaypoint(i)
                local target = {math.floor(x), math.floor(y)}
                table.insert(targets, {
                    target = target,
                    index = i,
                    link = navigationConfirmMenu({target = target, index = i}),
                })
            end
        end

        for _,obj in pairs(comms_target:getObjectsInRange(getLongRangeRadarRange())) do
            if isEeStation(obj) and not comms_target:isEnemy(obj) then
                table.insert(targets, {
                    target = obj,
                    link = navigationConfirmMenu({target = obj}),
                })
            end
        end

        config:navigationScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            targets = targets,
        }))
        return screen
    end


    navigationConfirmMenu = function(target)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            local success = config:navigationConfirmScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, target))

            if success == nil then
                logWarning("navigationScreen() should reply with true or false, but it replied with nil. Assuming 'true'.")
            end
            if success == true or success == nil then
                if isEeStation(target.target) then
                    comms_target:orderDock(target.target)
                elseif isVector2f(target.target) then
                    comms_target:orderFlyTowards(target.target[1], target.target[2])
                end
            end

            return screen
        end
    end

    -- don't ask me why, but if this is defined with its declaration it will be an empty table in the callbacks...
    defaultCallbackConfig = {
        linkToMainScreen = commandMenu,
        linkToDefendScreen = defendMenu,
        linkToAttackScreen = attackMenu,
        linkToNavigationScreen = navigationMenu,
    }

    return Comms.reply(config.label, commandMenu, function(comms_target, comms_source)
        if not isEeShip(comms_target) then
            logInfo("not displaying command in Comms, because target is not a ship. Got " .. type(comms_target))
            return false
        end
        return true
    end)
end