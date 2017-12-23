-- This comms script is a little ugly due to limitations in the Game Engine
--
-- It does not share context with the main script - so communication between those two
-- needs to be done with simple types. Calling setCommsMessage() somewhere else than in
-- this script will cause an error, because the call scope is not valid.
--
-- Fortunately it is possible to treat the objects as Lua Tables that are shared between the threads.
-- So information can be pushed around between those two threads.

require "src/lively_epsilon/util.lua"

function mainMenu()
    setCommsMessage("Hello World")
    if comms_target.getMissions ~= nil then
        addCommsReply("Do you have any missions for us?", function() missionsMenu() end)
    end

    if comms_target.getProductsSold ~= nil or comms_target.getProductsBought ~= nil then
        addCommsReply("Trading Board", function() tradeMenu() end)
    end
end

mainMenu()

--
-- Mission handling
--

function missionsMenu()
    if Util.size(comms_target:getMissions()) == 0 then
        setCommsMessage("Unfortunately we don't.");
    else
        local message = "Yes.\n\n"
        for _, value in pairs(comms_target:getMissions()) do
            message = message .. " * " .. value.title .. "\n"
            addCommsReply(value.title, function() missionDetail(value) end)
        end
        setCommsMessage(message);
    end
    addCommsReply("back", function() mainMenu() end)
end

function missionDetail(mission)
    local text = mission.title
    if type(mission.description) == "string" and mission.description ~= "" then
        text = text .. "\n\n" .. mission.description
    end

    if player.mission ~= nil then
        setCommsMessage(text .. "\n\nPlease finish your current mission before accepting a new one.")
    elseif player:isDocked(comms_target) then
        setCommsMessage(text)
        addCommsReply("Accept", function()
            comms_target:removeMission(mission.id)
            player:setMission(mission)
            setCommsMessage(mission.acceptMessage or "Please finish the mission as soon as possible.")
        end)
    else
        setCommsMessage(text .. "\n\nPlease dock with our station to accept the mission.")
    end
    addCommsReply("back", function() missionsMenu() end)
end

--
-- Buying and selling stuff
--

function tradeMenu()
    local buying = comms_target:getProductsBought()
    local selling = comms_target:getProductsSold()
    local message = ""

    --
    -- We sell...
    --
    if Util.size(selling) > 0 then
        message = message .. "We sell:\n"
        for _, product in pairs(selling) do
            message = message .. " * " .. product.name .. " at " .. comms_target:getProductSellingPrice(product) .. "$ per unit\n"
        end
        message = message .. "\n"
        addCommsReply("I want to buy something", function() tradeSell() end)
    end

    --
    -- We buy...
    --
    if Util.size(buying) > 0 then
        message = message .. "We buy:\n"
        for _, product in pairs(buying) do
            message = message .. " * " .. product.name .. " at " .. comms_target:getProductBuyingPrice(product) .. "$ per unit\n"
        end
        message = message .. "\n"
        addCommsReply("I want to sell something", function() tradeBuy() end)
    end

    --
    -- We produce...
    --
    if type(comms_target.getProducedProducts) == "function" then
        local produces = comms_target:getProducedProducts()

        if Util.size(produces) > 0 then
            for k, v in pairs(produces) do
                produces[k] = v.name
            end
            message = message .. "We produce " .. Util.mkString(produces, ", ", " and ") .. ".\n"
        end
    end
    if type(comms_target.getConsumedProducts) == "function" then
        local consumes = comms_target:getConsumedProducts()
        if Util.size(consumes) > 0 then
            for k, v in pairs(consumes) do consumes[k] = v.name end
            message = message .. "We consume " .. Util.mkString(consumes, ", ", " and ") .. ".\n"
        end
    end

    setCommsMessage(message)
    addCommsReply("back", function() mainMenu() end)
end

function tradeSell()
    local message = "We sell:\n"

    for _, product in pairs(comms_target:getProductsSold()) do
        message = message .. " * max. " .. comms_target:getMaxProductSelling(product) .. "x " .. product.name .. " at " .. comms_target:getProductSellingPrice(product) .. "$ per unit\n"
        addCommsReply("buy " .. product.name, function() tradeSellProduct(product) end)
    end

    setCommsMessage(message)

    addCommsReply("back", function() tradeMenu() end)
end

function tradeSellProduct(product)

    if comms_target:getMaxProductSelling(product) == 0 then
        setCommsMessage("We are short of supplies, so we can't sell " .. product.name .. " at the moment.")
    else
        setCommsMessage("We are willing to sell up to " .. comms_target:getMaxProductSelling(product) .. " units of " .. product.name .. " at a price of " .. comms_target:getProductSellingPrice(product) .. "$ per unit.")
    end

    addCommsReply("back", function() tradeSell() end)
end

function tradeBuy()
    local message = "We buy:\n"

    for _, product in pairs(comms_target:getProductsBought()) do
        message = message .. " * max. " .. comms_target:getMaxProductBuying(product) .. "x " .. product.name .. " at " .. comms_target:getProductBuyingPrice(product) .. "$ per unit\n"
        addCommsReply("sell " .. product.name, function() tradeBuyProduct(product) end)
    end

    setCommsMessage(message)
    addCommsReply("back", function() tradeMenu() end)
end

function tradeBuyProduct(product)

    if comms_target:getMaxProductBuying(product) == 0 then
        setCommsMessage("We are not in demand of " .. product.name .. ". Maybe check back at a later point.")
    else
        setCommsMessage("We would buy up to " .. comms_target:getMaxProductBuying(product) .. " units of " .. product.name .. " at a price of " .. comms_target:getProductBuyingPrice(product) .. "$ per unit.")
    end

    addCommsReply("back", function() tradeBuy() end)
end
