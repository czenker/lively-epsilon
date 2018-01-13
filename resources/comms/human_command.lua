humanCommandComms = Comms:commandFactory({
    -- the label that leads to these commands
    label = "Commands",

    -- This is the first screen the player sees after they told
    -- the captain they want to give them orders.
    --
    -- It is up to you how the captain reacts and which options are available.
    -- Give the player full command over the ship or laugh them in the face and close the channel.
    commandScreen = function(screen, comms_target, comms_source, config)
        if Ship:hasCrew(comms_target) and comms_target:hasCrewAtPosition("captain") then
            local captain = comms_target:getCrewAtPosition("captain")
            screen:addText("You are speaking to captain " .. captain:getFormalName() .. " directly.\n\n")
        end
        screen:addText("How can we help you?")

        screen:withReply(Comms.reply("Fly somewhere", config.linkToNavigationScreen))
        screen:withReply(Comms.reply("Defend a target", config.linkToDefendScreen))
        screen:withReply(Comms.reply("Attack a target", config.linkToAttackScreen))
        screen:withReply(Comms.reply("back"))
    end,

    -- The screen the player sees when they ask the captain to help them defend something
    --
    -- Still you can decide which objects you give as a selection
    defendScreen = function(screen, comms_target, comms_source, config)
        if isTable(config.targets) and Util.size(config.targets) > 0 then
            screen:addText("Where shall we go?")
            for _, conf in pairs(config.targets) do
                local target = conf.target
                local link = conf.link
                if isEeStation(target) then
                    screen:withReply(Comms.reply(target:getCallSign(), link))
                elseif isVector2f(target) then
                    screen:withReply(Comms.reply(target[1] .. ", " ..  target[2], link))
                end
            end
        else
            screen:addText("Our scanners do not show any valid targets around our current position. Can you set a waypoint?")
        end
        screen:withReply(Comms.reply("back", config.linkToMainScreen))
    end,

    -- The screen the player sees after they ordered the captain to defend a sepcific location or target.
    --
    -- You have to decide if the captain conforms to the request and return true or false.
    defendConfirmScreen = function(screen, comms_target, comms_source, config)
        local target = config.target
        if isEeStation(target) then
            screen:addText("Fine. We are going to assist " .. target:getCallSign())
        elseif isVector2f(target) then
            screen:addText("Fine. We are flying to " .. target[1] .. ", " .. target[2] .. " and wait for further orders.")
        end
        screen:withReply(Comms.reply("back"))
        return true
    end,

    -- The screen the player sees when they ask the captain to attack something
    --
    -- If you got a coward you will probably just reply "No" ;)
    attackScreen = function(screen, comms_target, comms_source, config)
        if isTable(config.targets) and Util.size(config.targets) > 0 then
            screen:addText("What shall we attack?")
            for _, conf in pairs(config.targets) do
                local target = conf.target
                local link = conf.link
                if isEeObject(target) then
                    screen:withReply(Comms.reply(target:getCallSign(), link))
                end
            end
        else
            screen:addText("We don't see any enemies on our radar.")
        end
        screen:withReply(Comms.reply("back", config.linkToMainScreen))
    end,

    -- The screen the player sees after they ordered the captain to attack a sepcific location or target.
    --
    -- You have to decide if the captain conforms to the request and return true or false.
    attackConfirmScreen = function(screen, comms_target, comms_source, config)
        local target = config.target
        local link = config.link
        if isEePlayer(target) then
            screen:addText("We don't know what problem you have with " .. target:getCallSign() .. ", but we don't care either. We will attack.")
        else
            screen:addText("We are going to attack " .. target:getCallSign() .. ".")
        end
        screen:withReply(Comms.reply("back"))
        return true
    end,

    -- The screen the player sees when they ask the captain to go somewhere
    navigationScreen = function(screen, comms_target, comms_source, config)
        if isTable(config.targets) and Util.size(config.targets) > 0 then
            screen:addText("Where shall we go?")
            for _, conf in pairs(config.targets) do
                local target = conf.target
                local link = conf.link
                if isEeStation(target) then
                    screen:withReply(Comms.reply(target:getCallSign(), link))
                elseif isVector2f(target) then
                    screen:withReply(Comms.reply(target[1] .. ", " ..  target[2], link))
                end
            end
        else
            screen:addText("Our scanners do not show any valid targets around our current position. Can you set a waypoint?")
        end
        screen:withReply(Comms.reply("back", config.linkToMainScreen))
    end,

    -- The screen the player sees after they ordered the captain to navigate to a sepcific location or dock at a target.
    --
    -- You have to decide if the captain conforms to the request and return true or false.
    navigationConfirmScreen = function(screen, comms_target, comms_source, config)
        local target = config.target
        if isEeStation(target) then
            screen:addText("Ok, we are going to dock at " .. target:getCallSign())
        elseif isVector2f(target) then
            screen:addText("Fine. We are flying to " .. target[1] .. ", " .. target[2] .. " and wait for further orders.")
        end
        screen:withReply(Comms.reply("back"))
        return true
    end,
})
