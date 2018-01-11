Comms = Comms or {}

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