humanMissionBrokerComms = Comms:missionBrokerFactory({
    -- the label that leads to these commands
    label = "Mission Board",

    mainScreen = function(self, screen, comms_target, comms_source, config)
        if Util.size(config.missions) == 0 then
            screen:addText("Unfortunately we do not have any missions at the moment.")
        else
            screen:addText("We have missions for you.\n\n")
            for _, conf in pairs(config.missions) do
                local mission = conf.mission
                local title = mission:getTitle()
                screen:addText(" * " .. title .. "\n")
                screen:withReply(Comms.reply(title, conf.link))
            end
        end
        screen:withReply(Comms.reply("back"))
    end,
    detailScreen = function(self, screen, comms_target, comms_source, config)
        local mission = config.mission
        local description = mission:getDescription()
        if isString(description) and description ~= "" then
            screen:addText("\n\n" .. description)
        end
        screen:withReply(
            Comms.reply("Accept", config.linkAccept)
        )

        screen:withReply(Comms.reply("back", config.linkToMainScreen))
    end,
    acceptScreen = function(self, screen, comms_target, comms_source, config)
        local mission = config.mission
        screen:addText(mission.getAcceptMessage())
        screen:withReply(Comms.reply("back"))

        return true
    end,
})
