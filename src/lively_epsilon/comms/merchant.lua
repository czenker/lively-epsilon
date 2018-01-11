Comms = Comms or {}

local merchantMenu
local tradeSell
local tradeSellProduct
local tradeBuy
local tradeBuyProduct

merchantMenu = function(comms_target, comms_source)
    local buying = comms_target:getProductsBought()
    local selling = comms_target:getProductsSold()
    local screen = Comms.screen()

    --
    -- We sell...
    --
    if Util.size(selling) > 0 then
        screen:addText("We sell:\n")
        for _, product in pairs(selling) do
            screen:addText(" * " .. product.name .. " at " .. comms_target:getProductSellingPrice(product) .. "$ per unit\n")
        end
        screen:addText("\n")
        screen:withReply(Comms.reply("I want to buy something", tradeSell))
    end

    --
    -- We buy...
    --
    if Util.size(buying) > 0 then
        screen:addText("We buy:\n")
        for _, product in pairs(buying) do
            screen:addText(" * " .. product.name .. " at " .. comms_target:getProductBuyingPrice(product) .. "$ per unit\n")
        end
        screen:addText("\n")
        screen:withReply(Comms.reply("I want to sell something", tradeBuy))
    end

    screen:withReply(Comms.reply("back"))
    return screen
end

tradeSell = function(comms_target, comms_source)
    local screen = Comms.screen("We sell:\n")

    for _, product in pairs(comms_target:getProductsSold()) do
        screen:addText(" * max. " .. comms_target:getMaxProductSelling(product) .. "x " .. product.name .. " at " .. comms_target:getProductSellingPrice(product) .. "$ per unit\n")
        screen:withReply(Comms.reply("buy " .. product.name, tradeSellProduct(product)))
    end

    screen:withReply(Comms.reply("back", merchantMenu))
    return screen
end

tradeSellProduct = function(product)
    return function(comms_target, comms_source)
        local screen = Comms.screen()
        if comms_target:getMaxProductSelling(product) == 0 then
            screen:addText("We are short of supplies, so we can't sell " .. product.name .. " at the moment.")
        else
            screen:addText("We are willing to sell up to " .. comms_target:getMaxProductSelling(product) .. " units of " .. product.name .. " at a price of " .. comms_target:getProductSellingPrice(product) .. "$ per unit.")
        end

        screen:withReply(Comms.reply("back", tradeSell))
        return screen
    end
end

tradeBuy = function(comms_target, comms_source)
    local screen = Comms.screen("We buy:\n")

    for _, product in pairs(comms_target:getProductsBought()) do
        screen:addText(" * max. " .. comms_target:getMaxProductBuying(product) .. "x " .. product.name .. " at " .. comms_target:getProductBuyingPrice(product) .. "$ per unit\n")
        screen:withReply(Comms.reply("sell " .. product.name, tradeBuyProduct(product)))
    end

    screen:withReply(Comms.reply("back", merchantMenu))
    return screen
end

tradeBuyProduct = function(product)
    return function(comms_target, comms_source)
        local screen = Comms.screen()
        if comms_target:getMaxProductBuying(product) == 0 then
            screen:addText("We are not in demand of " .. product.name .. ". Maybe check back at a later point.")
        else
            screen:addText("We would buy up to " .. comms_target:getMaxProductBuying(product) .. " units of " .. product.name .. " at a price of " .. comms_target:getProductBuyingPrice(product) .. "$ per unit.")
        end

        screen:withReply(Comms.reply("back", tradeBuy))
        return screen
    end
end

Comms.defaultMerchant = Comms.reply("Merchant", merchantMenu)