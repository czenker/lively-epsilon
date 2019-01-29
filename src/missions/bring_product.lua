Missions = Missions or {}

--- The players need to bring a certain amount of products to the station.
---
--- It does not matter how they are achieved (mining, piracy, trading) for this mission.
---
--- @param self
--- @param station SpaceStation
--- @param config table
---   @subparam product Product the product the players have to bring
---   @subparam amount number number of units the player have to bring
---   @subparam acceptCondition function
---   @subparam onAccept function
---   @subparam onDecline function
---   @subparam onStart function
---   @subparam onDelivery function
---   @subparam successScreen function
---   @subparam sellProductScreen function
---   @subparam commsLabel string
---   @subparam sellProductScreen function
---   @subparam onSuccess function
---   @subparam onFailure function
---   @subparam onEnd function
Missions.bringProduct = function(self, station, config)
    if not isEeStation(station) then error("Expected a station, but got " .. typeInspect(station), 2) end
    if not Station:hasComms(station) then error("Expected station to have comms, but it does not.", 2) end

    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end
    local product = config.product
    if not Product:isProduct(product) then error("Expected a product, but got " .. typeInspect(product), 2) end

    local totalAmount = config.amount or 1
    local broughtAmount = 0
    if not isNumber(totalAmount) then error("Expected a number as amount, but got " .. typeInspect(totalAmount), 2) end
    local commsId = "bring_product_" .. Util.randomUuid()

    local mission

    mission = Mission:new({
        acceptCondition = config.acceptCondition,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(config.onStart) then config.onStart(self) end

            local sellProductMenu
            sellProductMenu = function(amount)
                amount = amount or 0
                return function(comms_target, comms_source)
                    if amount > 0 then
                        if not Player:hasStorage(comms_source) then
                            logWarning("Player Ship has no storage, but an action to sell " .. product:getName() .. " was called. Probably an issue in your comms script.")
                            amount = 0
                        elseif comms_source:getProductStorage(product) < amount then
                            logWarning("Player does not have enough " .. product:getName() .. " to sell " .. amount .. " units.")
                            amount = comms_source:getProductStorage(product)
                        end
                        if totalAmount - broughtAmount < amount then
                            logWarning("The mission does not require to sell more than " .. amount .. " units of " .. product:getName() .. ".")
                            amount = totalAmount - broughtAmount
                        end
                    end

                    if amount > 0 then
                        comms_source:modifyProductStorage(product, -1 * amount)
                        broughtAmount = broughtAmount + amount

                        if isFunction(config.onDelivery) then config.onDelivery(mission, amount, comms_source) end
                    end

                    local screen = Comms.screen()

                    if broughtAmount >= totalAmount then
                        config.successScreen(mission, screen, comms_source)
                        mission:success()
                    else
                        local remainingAmount = totalAmount - broughtAmount
                        local playerAmount = 0
                        if Player:hasStorage(comms_source) then
                            playerAmount = comms_source:getProductStorage(product)
                        end
                        config.sellProductScreen(mission, screen, comms_source, {
                            justBroughtAmount = amount,
                            remainingAmount = remainingAmount,
                            playerLoadedAmount = playerAmount,
                            maxAmount = math.min(remainingAmount, playerAmount),
                            link = sellProductMenu,
                        })
                    end

                    return screen
                end
            end

            local reply = Comms.reply(config.commsLabel, sellProductMenu())
            station:addComms(reply, commsId)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            if isFunction(config.onEnd) then config.onEnd(self) end

            station:removeComms(commsId)
        end,
    })

    mission.getProduct = function() return product end

    mission.getTotalAmount = function() return totalAmount end

    mission.getBroughtAmount = function() return broughtAmount end

    return mission
end