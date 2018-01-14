local steps = {20, 5, 1}
local f = string.format -- I hate typing

humanMerchantComms = Comms:merchantFactory({
    -- the label that leads to these commands
    label = "Merchant",

    -- the initial screen that the player sees
    mainScreen = function(screen, comms_target, comms_source, config)
        --
        -- We sell...
        --
        if Util.size(config.selling) > 0 then
            screen:addText("We sell:\n")
            for _, sold in pairs(config.selling) do
                local product = sold.product
                screen:addText(f(" * %s   at   %0.2fRP   per unit\n", product:getName(), sold.price))
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
                screen:addText(f(" * %s   at   %0.2fRP   per unit\n", product:getName(), bought.price))
            end
            screen:addText("\n")
            screen:withReply(Comms.reply("I want to sell something", config.linkToBuyScreen))
        end

        screen:withReply(Comms.reply("back"))
    end,

    -- the screen the player sees when they say they want to buy something
    buyScreen = function(screen, comms_target, comms_source, config)
        if Util.size(config.buying) > 0 then
            screen:addText("We buy:\n")
            for _, bought in pairs(config.buying) do
                local product = bought.product
                screen:addText(f(" * %d   x   %s   at   %0.2fRP   per unit\n", bought.stationAmount, product:getName(), bought.price))
                screen:withReply(Comms.reply(f("Sell %s", product:getName()), bought.link))
            end
            screen:addText("\n")
            screen:withReply(Comms.reply("Well, maybe not", config.linkToMainScreen))
        end
    end,

    -- the screen the player sees when they selected a product they want to buy
    buyProductScreen = function(screen, comms_target, comms_source, config)
        local product = config.product
        if config.stationAmount == 0 then
            screen:addText(f("We are not in demand of %s at the moment.", product:getName()))
            screen:withReply(Comms.reply("back", config.linkToBuyScreen))
        else
            screen:addText(f("We are willing to buy up to %d units of %s at a price of %0.2fRP per unit\n\n", config.stationAmount, product:getName() , config.price))
            if not config.isDocked then
                screen:withReply(Comms.reply("Good to know", config.linkToBuyScreen))
            elseif config.playerAmount == 0 then
                screen:withReply(Comms.reply("Sorry, can't help you right now", config.linkToBuyScreen))
            else
                if config.amount > 0 then
                    screen:withReply(Comms.reply(f("Sell %d units for %0.2fRP", config.amount, config.cost), config.linkConfirm(config.amount)))
                else
                    screen:withReply(Comms.reply(f("Sell %d units for %0.2fRP", config.maxTradableAmount, (config.maxTradableAmount * config.price)), config.linkConfirm(config.maxTradableAmount)))
                end
                for _,i in ipairs(steps) do
                    if config.maxTradableAmount - config.amount >= i then
                        local label
                        if i == 1 then label = "1 unit" else label = f("%d units", i) end
                        if config.amount > 0 then label = "+" .. label end
                        screen:withReply(Comms.reply(label, config.linkAmount(config.amount + i)))
                    end
                end
                screen:withReply(Comms.reply("back", config.linkToBuyScreen))
            end
        end
    end,

    -- here is the place to thank the player for their offer
    buyProductConfirmScreen = function(screen, comms_target, comms_source, config)
        local product = config.product
        screen:addText(f("Glad to make business with you. We received the %s and send you the payment of %0.2fRP.", product:getName(), config.cost))
        screen:withReply(Comms.reply("See you", config.linkToMainScreen))

        return true
    end,

    -- the screen the player sees when they say they want to sell something
    sellScreen = function(screen, comms_target, comms_source, config)
        if Util.size(config.selling) > 0 then
            screen:addText("We sell:\n")
            for _, sold in pairs(config.selling) do
                local product = sold.product
                screen:addText(f(" * %d   x   %s   at   %0.2fRP   per unit\n", sold.stationAmount, product:getName(), sold.price))
                screen:withReply(Comms.reply(f("Buy %s", product:getName()), sold.link))
            end
            screen:addText("\n")
            screen:withReply(Comms.reply("Well, maybe not", config.linkToMainScreen))
        end
    end,

    -- the screen the player sees when they selected a product they want to sell
    sellProductScreen = function(screen, comms_target, comms_source, config)
        local product = config.product
        if config.stationAmount == 0 then
            screen:addText(f("We are short of supplies, so we can't sell %s at the moment.", product:getName()))
            screen:withReply(Comms.reply("back", config.linkToSellScreen))
        else
            screen:addText(f("We are willing to sell up to %d units of %s at a price of %0.2fRP per unit.", config.stationAmount, product:getName(), config.price))
            if not config.isDocked then
                screen:withReply(Comms.reply("Good to know", config.linkToSellScreen))
            elseif config.playerAmount == 0 then
                screen:withReply(Comms.reply("Our storage is full", config.linkToSellScreen))
            elseif config.affordableAmount == 0 then
                screen:withReply(Comms.reply("That's too expensive for us", config.linkToSellScreen))
            else
                if config.amount > 0 then
                    screen:withReply(Comms.reply(f("Buy %d units for %0.2fRP", config.amount, config.cost), config.linkConfirm(config.amount)))
                else
                    screen:withReply(Comms.reply(f("Buy %d units for %0.2fRP", config.maxTradableAmount, (config.maxTradableAmount * config.price)), config.linkConfirm(config.maxTradableAmount)))
                end
                for _,i in ipairs(steps) do
                    if config.maxTradableAmount - config.amount >= i then
                        local label
                        if i == 1 then label = "1 unit" else label = f("%d units", i) end
                        if config.amount > 0 then label = "+" .. label end
                        screen:withReply(Comms.reply(label, config.linkAmount(config.amount + i)))
                    end
                end
                screen:withReply(Comms.reply("back", config.linkToSellScreen))
            end
        end
    end,

    -- here is the place to thank the player for their purchase
    sellProductConfirmScreen = function(screen, comms_target, comms_source, config)
        local product = config.product
        screen:addText(f("The %d units of %s have been loaded to your ship and the %0.2fRP are transfered.", config.amount, product:getName(), config.cost))
        screen:withReply(Comms.reply("Great making business with you", config.linkToMainScreen))

        return true
    end,
})
