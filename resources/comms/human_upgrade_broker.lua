humanUpgradeBrokerComms = Comms:upgradeBrokerFactory({
    -- the label that leads to these commands
    label = "Ship Upgrades",

    mainScreen = function(self, screen, comms_target, comms_source, info)
        if Util.size(info.upgrades) == 0 then
            screen:addText("Unfortunately we do not have any upgrades at the moment.")
        else
            screen:addText("We have upgrades for you.\n\n")
            for _, conf in pairs(info.upgrades) do
                local upgrade = conf.upgrade
                local name = upgrade:getName()
                screen:addText(" * " .. name .. "\n")
                screen:withReply(Comms.reply(name, conf.link))
            end
        end
        screen:withReply(Comms.reply("back"))
    end,
    detailScreen = function(self, screen, comms_target, comms_source, info)
        local upgrade = info.upgrade
        screen:addText(upgrade:getName() .. "\n\n")
        local description = upgrade:getDescription(comms_source)
        if isString(description) and description ~= "" then
            screen:addText(description .. "\n\n")
        end
        if not comms_source:isDocked(comms_target) then
            screen:addText(string.format("Dock with our station and I will be able to install the update for %0.2fRP.", info.price))
        elseif not info.isAffordable then
            screen:addText(string.format("The upgrade price of %0.2fRP seems to be more than you can afford.", info.price))
        else
            screen:addText(string.format("I can install the upgrade on your ship for just %0.2fRP.", info.price))
            screen:withReply(
                Comms.reply("Buy", info.linkInstall)
            )
        end

        screen:withReply(Comms.reply("back", info.linkToMainScreen))
    end,
    installScreen = function(self, screen, comms_target, comms_source, info)
        local upgrade = info.upgrade
        screen:addText(upgrade:getInstallMessage(comms_source) or (upgrade:getName() .. " installed."))
        screen:withReply(Comms.reply("back"))

        return true
    end,
})
