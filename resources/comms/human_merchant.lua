humanMerchantComms = Comms:merchantFactory({
    -- the label that leads to these commands
    label = "Merchant",

    mainScreen = function(screen, comms_target, comms_source, config)
        --
        -- We sell...
        --
        if Util.size(config.selling) > 0 then
            screen:addText("We sell:\n")
            for _, sold in pairs(config.selling) do
                local product = sold.product
                screen:addText(" * " .. product:getName() .. " at " .. sold.price .. "RP per unit\n")
            end
            screen:addText("\n")
            screen:withReply(Comms.reply("I want to buy something", config.linkToSellScreen))
        end

        --
        -- We buy...
        --
        if Util.size(config.buying) > 0 then
            screen:addText("We buy:\n")
            for _, bought in pairs(config.buying) do
                local product = bought.product
                screen:addText(" * " .. product:getName() .. " at " .. bought.price .. "RP per unit\n")
            end
            screen:addText("\n")
            screen:withReply(Comms.reply("I want to sell something", config.linkToBuyScreen))
        end

        screen:withReply(Comms.reply("back"))
    end,
    buyScreen = function(screen, comms_target, comms_source, config)

        if Util.size(config.buying) > 0 then
            screen:addText("We buy:\n")
            for _, bought in pairs(config.buying) do
                local product = bought.product
                screen:addText(" * " .. product:getName() .. " at " .. bought.price .. "RP per unit\n")
                screen:withReply(Comms.reply("Sell " .. product:getName(), bought.link))
            end
            screen:addText("\n")
            screen:withReply(Comms.reply("Well, maybe not", config.linkToMainScreen))
        end
    end,
    buyProductScreen = function(screen, comms_target, comms_source, config)
        local product = config.product
        if config.maxAmount == 0 then
            screen:addText("We are not in demand of " .. product:getName() .. " at the moment.")
        else
            screen:addText("We are willing to buy up to " .. config.maxAmount .. " units of " .. product:getName() .. " at a price of " .. config.price .. "RP per unit.")
        end
        screen:withReply(Comms.reply("Too bad. My ship has no storage room.", config.linkToBuyScreen))
    end,
    sellScreen = function(screen, comms_target, comms_source, config)
        if Util.size(config.selling) > 0 then
            screen:addText("We sell:\n")
            for _, sold in pairs(config.selling) do
                local product = sold.product
                screen:addText(" * " .. product:getName() .. " at " .. sold.price .. "RP per unit\n")
                screen:withReply(Comms.reply("Buy " .. product:getName(), sold.link))
            end
            screen:addText("\n")
            screen:withReply(Comms.reply("Well, maybe not", config.linkToMainScreen))
        end
    end,
    sellProductScreen = function(screen, comms_target, comms_source, config)
        local product = config.product
        if config.maxAmount == 0 then
            screen:addText("We are short of supplies, so we can't sell " .. product:getName() .. " at the moment.")
        else
            screen:addText("We are willing to sell up to " .. config.maxAmount .. " units of " .. product:getName() .. " at a price of " .. config.price .. "RP per unit.")
        end
        screen:withReply(Comms.reply("Too bad. My ship has no storage room.", config.linkToSellScreen))
    end,
})
