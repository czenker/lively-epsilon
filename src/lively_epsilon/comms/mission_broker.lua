Comms = Comms or {}

Comms.missionBrokerFactory = function(self, config)
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    if not isString(config.label) and not isFunction(config.label) then error("expected label to be a string or function, but got " .. type(config.label), 2) end
    if not isFunction(config.mainScreen) then error("expected mainScreen to be a function, but got " .. type(config.mainScreen), 2) end
    if not isFunction(config.detailScreen) then error("expected buyScreen to be a function, but got " .. type(config.detailScreen), 2) end
    if not isFunction(config.acceptScreen) then error("expected buyProductScreen to be a function, but got " .. type(config.acceptScreen), 2) end

    local mainMenu
    local detailMenu
    local acceptMenu

    local defaultCallbackConfig

    local formatMission = function(mission, station, player)
        return {
            mission = mission,
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
        config.mainScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            missions = formatMissions(comms_target, comms_source),
        }))
        return screen
    end

    detailMenu = function(mission)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            config.detailScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, formatMission(mission, comms_target, comms_source)))
            return screen
        end
    end

    acceptMenu = function(mission)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            local success = config.acceptScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, formatMission(mission, comms_target, comms_source)))
            if success == nil then
                logWarning("acceptScreen() should reply with true or false, but it replied with nil. Assuming 'true'.")
            end
            if success == true or success == nil then
            end
                mission:setPlayer(comms_source)
                mission:setMissionBroker(comms_target)
                comms_target:removeMission(mission)

                if Player:hasMissionTracker(comms_source) then
                    comms_source:addMission(mission)
                end

                mission:accept()
                mission:start()
            return screen
        end
    end


    -- don't ask me why, but if this is defined with its declaration it will be an empty table in the callbacks...
    defaultCallbackConfig = {
        linkToMainScreen = mainMenu,
    }

    return Comms.reply(config.label, mainMenu)
end















local missionAccept
local missionDetail
local missionsMenu

missionsMenu = function(comms_target, comms_source)
    if not Station:hasMissionBroker(comms_target) then
        return nil
    end
    local missions = comms_target:getMissions()
    local screen = Comms.screen("")

    if Util.size(missions) == 0 then
        screen:addText("Unfortunately we do not have any missions at the moment.")
    else
        screen:addText("We have missions for you.\n\n")
        for _, mission in pairs(missions) do

            local title = mission:getTitle()
            screen:addText(" * " .. title .. "\n")
            screen:withReply(Comms.reply(title, missionDetail(mission)))
        end
    end
    screen:withReply(Comms.reply("back"))

    return screen
end

missionDetail = function(mission)
    return function(comms_target, comms_source)
        local screen = Comms.screen(mission.getTitle())

        local description = mission:getDescription()
        if isString(description) and description ~= "" then
            screen:addText("\n\n" .. description)
        end
        screen:withReply(
            Comms.reply("Accept", missionAccept(mission))
        )

        screen:withReply(Comms.reply("back", missionsMenu))
        return screen
    end
end

missionAccept = function(mission)
    return function(comms_target, comms_source)
        mission:setPlayer(comms_source)
        mission:setMissionBroker(comms_target)
        comms_target:removeMission(mission)

        if Player:hasMissionTracker(comms_source) then
            comms_source:addMission(mission)
        end

        mission:accept()
        mission:start()

        return Comms.screen(mission.getAcceptMessage(), {Comms.reply("back")})
    end
end

Comms.defaultMissionBoard = Comms.reply("Mission Board", missionsMenu)