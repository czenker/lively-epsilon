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
        addCommsReply("Habt ihr einen Auftrag fuer uns?", function() missionsMenu() end)
    end

    if comms_target.getProductsSold ~= nil or comms_target.getProductsBought ~= nil then
        addCommsReply("Handelsbrett", function() tradeMenu() end)
    end
end

mainMenu()

--
-- Mission handling
--

function missionsMenu()
    if Util.size(comms_target:getMissions()) == 0 then
        setCommsMessage("Leider nein");
    else
        local message = "Ja!!!\n\n"
        for _, value in pairs(comms_target:getMissions()) do
            message = message .. " * " .. value.title .. "\n"
            addCommsReply(value.title, function() missionDetail(value) end)
        end
        setCommsMessage(message);
    end
    addCommsReply("zurueck", function() mainMenu() end)
end

function missionDetail(mission)
    local text = mission.title
    if type(mission.description) == "string" and mission.description ~= "" then
        text = text .. "\n\n" .. mission.description
    end

    if player.mission ~= nil then
        setCommsMessage(text .. "\n\nBitte beenden Sie zunaechst ihre aktuelle Mission, bevor Sie eine neue annehmen.")
    elseif player:isDocked(comms_target) then
        setCommsMessage(text)
        addCommsReply("Annehmen", function()
            comms_target:removeMission(mission.id)
            player:setMission(mission)
            setCommsMessage(mission.acceptMessage or "Bitte bringen Sie die Mission so bald wie möglich zu Ende.")
        end)
    else
        setCommsMessage(text .. "\n\nBitte docken Sie an unserer Station um den Auftrag anzunehmen.")
    end
    addCommsReply("zurueck", function() missionsMenu() end)
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
        message = message .. "Wir verkaufen:\n"
        for _, product in pairs(selling) do
            message = message .. " * " .. product.name .. " fuer " .. comms_target:getProductSellingPrice(product) .. "$ pro Einheit\n"
        end
        message = message .. "\n"
        addCommsReply("Ich moechte etwas kaufen", function() tradeSell() end)
    end

    --
    -- We buy...
    --
    if Util.size(buying) > 0 then
        message = message .. "Wir kaufen:\n"
        for _, product in pairs(buying) do
            message = message .. " * " .. product.name .. " fuer " .. comms_target:getProductBuyingPrice(product) .. "$ pro Einheit\n"
        end
        message = message .. "\n"
        addCommsReply("Ich moechte etwas verkaufen", function() tradeBuy() end)
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
            message = message .. "Wir produzieren " .. Util.mkString(produces, ", ", " und ") .. ".\n"
        end
    end
    if type(comms_target.getConsumedProducts) == "function" then
        local consumes = comms_target:getConsumedProducts()
        if Util.size(consumes) > 0 then
            for k, v in pairs(consumes) do consumes[k] = v.name end
            message = message .. "Wir konsumieren " .. Util.mkString(consumes, ", ", " und ") .. ".\n"
        end
    end

    setCommsMessage(message)
    addCommsReply("zurueck", function() mainMenu() end)
end

function tradeSell()
    local message = "Wir verkaufen:\n"

    for _, product in pairs(comms_target:getProductsSold()) do
        message = message .. " * max. " .. comms_target:getMaxProductSelling(product) .. "x " .. product.name .. " fuer " .. comms_target:getProductSellingPrice(product) .. "$ pro Einheit\n"
        addCommsReply(product.name .. " kaufen", function() tradeSellProduct(product) end)
    end

    setCommsMessage(message)

    addCommsReply("zurueck", function() tradeMenu() end)
end

function tradeSellProduct(product)

    if comms_target:getMaxProductSelling(product) == 0 then
        setCommsMessage("Augrund geringer Bestaende koennen wir " .. product.name .. " im Augenblick nicht verkaufen.")
    else
        setCommsMessage("Wir sind bereit bis zu " .. comms_target:getMaxProductSelling(product) .. " Einheiten " .. product.name .. " zu einem Preis von " .. comms_target:getProductSellingPrice(product) .. "$ pro Einheit zu verkaufen.")
    end

    addCommsReply("zurueck", function() tradeSell() end)
end

function tradeBuy()
    local message = "Wir kaufen:\n"

    for _, product in pairs(comms_target:getProductsBought()) do
        message = message .. " * max. " .. comms_target:getMaxProductBuying(product) .. "x " .. product.name .. " fuer " .. comms_target:getProductBuyingPrice(product) .. "$ pro Einheit\n"
        addCommsReply(product.name .. " verkaufen", function() tradeBuyProduct(product) end)
    end

    setCommsMessage(message)
    addCommsReply("zurueck", function() tradeMenu() end)
end

function tradeBuyProduct(product)

    if comms_target:getMaxProductBuying(product) == 0 then
        setCommsMessage("Wir haben im Augenblick keinen Bedarf an " .. product.name .. ", aber vielleicht zu einem spaeteren Zeitpunkt.")
    else
        setCommsMessage("Wir sind bereit bis zu " .. comms_target:getMaxProductBuying(product) .. " Einheiten " .. product.name .. " zu einem Preis von " .. comms_target:getProductBuyingPrice(product) .. "$ pro Einheit zu kaufen.")
    end

    addCommsReply("zurueck", function() tradeBuy() end)
end
