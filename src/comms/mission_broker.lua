Comms = Comms or {}

Comms.missionBrokerFactory = function(self, config)
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    if not isString(config.label) and not isFunction(config.label) then error("expected label to be a string or function, but got " .. typeInspect(config.label), 2) end
    if not isFunction(config.mainScreen) then error("expected mainScreen to be a function, but got " .. typeInspect(config.mainScreen), 2) end
    if not isFunction(config.detailScreen) then error("expected buyScreen to be a function, but got " .. typeInspect(config.detailScreen), 2) end
    if not isFunction(config.acceptScreen) then error("expected buyProductScreen to be a function, but got " .. typeInspect(config.acceptScreen), 2) end
    if not isNil(config.displayCondition) and not isFunction(config.displayCondition) then error("expected displayCondition to be a function, but got " .. typeInspect(config.displayCondition), 2) end

    local mainMenu
    local detailMenu
    local acceptMenu

    local defaultCallbackConfig

    local formatMission = function(mission, station, player)
        if Mission:isPlayerMission(mission) then
            mission:setPlayer(player)
        end
        if Mission:isBrokerMission(mission) then
            mission:setMissionBroker(station)
        end
        local canBeAccepted, canBeAcceptedMessage = mission:canBeAccepted()
        return {
            mission = mission,
            canBeAccepted = canBeAccepted,
            canBeAcceptedMessage = canBeAcceptedMessage,
            link = detailMenu(mission),
            linkAccept = acceptMenu(mission),
        }
    end

    local formatMissions = function(station, player)
        local ret = {}
        for _, mission in pairs(station:getMissions()) do
            ret[mission:getId()] = formatMission(mission, station, player)
        end
        return ret
    end

    mainMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config:mainScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            missions = formatMissions(comms_target, comms_source),
        }))
        return screen
    end

    detailMenu = function(mission)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            config:detailScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, formatMission(mission, comms_target, comms_source)))
            return screen
        end
    end

    acceptMenu = function(mission)
        return function(comms_target, comms_source)
            local missionInfo = formatMission(mission, comms_target, comms_source)
            local screen = Comms.screen()
            local success = config:acceptScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, missionInfo))
            if not missionInfo.canBeAccepted then
                if success == true then
                    logWarning("The mission " .. mission:getId() .. " can not be accepted. This seems to be a problem with your comms screen.")
                end
                success = false
            elseif success == nil then
                logWarning("acceptScreen() should reply with true or false, but it replied with nil. Assuming 'true'.")
            end
            if success == true or success == nil then
                if Mission:isPlayerMission(mission) then
                    mission:setPlayer(comms_source)
                end
                if Mission:isBrokerMission(mission) then
                    mission:setMissionBroker(comms_target)
                end
                comms_target:removeMission(mission)
                if Player:hasMissionTracker(comms_source) then
                    comms_source:addMission(mission)
                end

                mission:accept()
                mission:start()
            end
            return screen
        end
    end


    -- don't ask me why, but if this is defined with its declaration it will be an empty table in the callbacks...
    defaultCallbackConfig = {
        linkToMainScreen = mainMenu,
    }

    return Comms.reply(config.label, mainMenu, function(comms_target, comms_source)
        if not Station:hasMissionBroker(comms_target) then
            logInfo("not displaying mission_broker in Comms, because target has no mission_broker.")
            return false
        elseif userCallback(config.displayCondition, self, comms_target, comms_source) == false then
            return false
        end
        return true
    end)
end
