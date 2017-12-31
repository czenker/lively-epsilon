Comms = Comms or {}

local missionAccept
local missionDetail
local missionsMenu

missionsMenu = function(comms_target, comms_source)
    if not hasMissions(comms_target) then
        return nil
    end
    local missions = comms_target:getMissions()
    local screen = Comms.screen("")

    if Util.size(missions) == 0 then
        screen:addText("Unfortunately we do not have any missions at the moment.")
    else
        screen:addText("We have missions for you.\n\n")
        for _, mission in pairs(missions) do
            screen:addText(" * " .. mission.title .. "\n")
            screen:withReply(Comms.reply(mission.title, missionDetail(mission)))
        end
    end
    screen:withReply(Comms.reply("back"))

    return screen
end

missionDetail = function(mission)
    return function(comms_target, comms_source)
        local screen = Comms.screen(mission.title)

        if isString(mission.description) and mission.description ~= "" then
            screen:addText("\n\n" .. mission.description)
        end

        if comms_source.mission ~= nil then
            screen:addText("\n\nPlease finish your current mission before accepting a new one.")
        elseif comms_source:isDocked(comms_target) then
            screen:withReply(
            Comms.reply("Accept", missionAccept(mission))
            )
        else
            screen:addText("\n\nPlease dock with our station to accept the mission.")
        end

        screen:withReply(Comms.reply("back", missionsMenu))
        return screen
    end
end

missionAccept = function(mission)
    return function(comms_target, comms_source)
        comms_target:removeMission(mission.id)
        comms_source:setMission(mission)

        return Comms.screen(mission.acceptMessage or "Please finish the mission as soon as possible.", {Comms.reply("back")})
    end
end

Comms.defaultMissionBoard = missionsMenu