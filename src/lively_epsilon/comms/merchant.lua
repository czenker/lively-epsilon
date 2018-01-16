Comms = Comms or {}

Comms.merchantFactory = function(self, config)
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    if not isString(config.label) and not isFunction(config.label) then error("expected label to be a string or function, but got " .. type(config.label), 2) end
    if not isFunction(config.mainScreen) then error("expected mainScreen to be a function, but got " .. type(config.mainScreen), 2) end
    if not isFunction(config.buyScreen) then error("expected buyScreen to be a function, but got " .. type(config.buyScreen), 2) end
    if not isFunction(config.buyProductScreen) then error("expected buyProductScreen to be a function, but got " .. type(config.buyProductScreen), 2) end
    if not isFunction(config.buyProductConfirmScreen) then error("expected buyProductConfirmScreen to be a function, but got " .. type(config.buyProductConfirmScreen), 2) end
    if not isFunction(config.sellScreen) then error("expected sellScreen to be a function, but got " .. type(config.sellScreen), 2) end
    if not isFunction(config.sellProductScreen) then error("expected sellProductScreen to be a function, but got " .. type(config.sellProductScreen), 2) end
    if not isFunction(config.sellProductConfirmScreen) then error("expected sellProductConfirmScreen to be a function, but got " .. type(config.sellProductConfirmScreen), 2) end

    local mainMenu
    local buyMenu
    local buyProductMenu
    local buyProductConfirmMenu
    local sellMenu
    local sellProductMenu
    local sellProductConfirmMenu

    local defaultCallbackConfig

    local formatBoughtProduct = function(product, station, player)
        return {
            product = product,
            price = station:getProductBuyingPrice(product, player),
            stationAmount = station:getMaxProductBuying(product, player),
            playerAmount = player:getProductStorage(product),
            maxTradableAmount = math.min(
                station:getMaxProductBuying(product, player),
                player:getProductStorage(product)
            ),
            isDocked = player:isDocked(station),
            link = buyProductMenu(product),
            linkAmount = function(amount) return buyProductMenu(product, amount) end,
            linkConfirm = function(amount) return buyProductConfirmMenu(product, amount) end,
        }
    end

    local formatBoughtProducts = function(station, player)
        local ret = {}
        for _, product in pairs(station:getProductsBought(player)) do
            ret[product:getId()] = formatBoughtProduct(product, station, player)
        end
        return ret
    end

    local formatSoldProduct = function(product, station, player)
        local affordableAmount = math.floor(player:getReputationPoints() / station:getProductSellingPrice(product, player))
        return {
            product = product,
            price = station:getProductSellingPrice(product, player),
            stationAmount = station:getMaxProductSelling(product, player),
            playerAmount = player:getEmptyProductStorage(product),
            affordableAmount = affordableAmount,
            maxTradableAmount = math.min(
                station:getMaxProductSelling(product, player),
                player:getEmptyProductStorage(product),
                affordableAmount
            ),
            isDocked = player:isDocked(station),
            link = sellProductMenu(product),
            linkAmount = function(amount) return sellProductMenu(product, amount) end,
            linkConfirm = function(amount) return sellProductConfirmMenu(product, amount) end,
        }
    end

    local formatSoldProducts = function(station, player)
        local ret = {}
        for _, product in pairs(station:getProductsSold(player)) do
            ret[product:getId()] = formatSoldProduct(product, station, player)
        end
        return ret
    end

    mainMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config:mainScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            buying = formatBoughtProducts(comms_target, comms_source),
            selling = formatSoldProducts(comms_target, comms_source),
        }))
        return screen
    end

    buyMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config:buyScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            buying = formatBoughtProducts(comms_target, comms_source),
        }))
        return screen
    end

    buyProductMenu = function(product, amount)
        amount = amount or 0
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            local info = formatBoughtProduct(product, comms_target, comms_source)
            config:buyProductScreen(screen, comms_target, comms_source, Util.mergeTables(
                defaultCallbackConfig,
                info,
                {
                    amount = amount,
                    cost = amount * info.price,
                }
            ))
            return screen
        end
    end

    buyProductConfirmMenu = function(product, amount)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            local info = formatBoughtProduct(product, comms_target, comms_source)
            amount = math.min(
                amount or 9999,
                info.stationAmount,
                info.playerAmount
            )
            local success = config:buyProductConfirmScreen(screen, comms_target, comms_source, Util.mergeTables(
                defaultCallbackConfig,
                info,
                {
                    amount = amount,
                    cost = amount * info.price,
                }
            ))
            if success == nil then
                logWarning("buyProductConfirmScreen() should reply with true or false, but it replied with nil. Assuming 'true'.")
            end
            if success == true or success == nil then
                comms_source:modifyProductStorage(product, -1 * amount)
                comms_target:modifyProductStorage(product, 1 * amount)
                comms_source:addReputationPoints(amount * info.price)
            end
            return screen
        end
    end

    sellMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config:sellScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            selling = formatSoldProducts(comms_target, comms_source),
        }))
        return screen
    end

    sellProductMenu = function(product, amount)
        amount = amount or 0
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            local info = formatSoldProduct(product, comms_target, comms_source)
            config:sellProductScreen(screen, comms_target, comms_source, Util.mergeTables(
                defaultCallbackConfig,
                info,
                {
                    amount = amount,
                    cost = amount * info.price,
                }
            ))
            return screen
        end
    end

    sellProductConfirmMenu = function(product, amount)
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            local info = formatSoldProduct(product, comms_target, comms_source)
            amount = math.min(
                amount or 9999,
                info.stationAmount,
                info.playerAmount,
                info.affordableAmount
            )
            local success = config:sellProductConfirmScreen(screen, comms_target, comms_source, Util.mergeTables(
                defaultCallbackConfig,
                info,
                {
                    amount = amount,
                    cost = amount * info.price,
                }
            ))
            if success == nil then
                logWarning("sellProductConfirmScreen() should reply with true or false, but it replied with nil. Assuming 'true'.")
            end
            if success == true or success == nil then
                comms_source:modifyProductStorage(product, 1 * amount)
                comms_target:modifyProductStorage(product, -1 * amount)
                comms_source:takeReputationPoints(amount * info.price)
            end
            return screen
        end
    end


    -- don't ask me why, but if this is defined with its declaration it will be an empty table in the callbacks...
    defaultCallbackConfig = {
        linkToMainScreen = mainMenu,
        linkToBuyScreen = buyMenu,
        linkToSellScreen = sellMenu,
    }

    return Comms.reply(config.label, mainMenu, function(comms_target, comms_source)
        if not Station:hasMerchant(comms_target) or not Player:hasStorage(comms_source) then
            logInfo("not displaying merchant in Comms, because target has no merchant.")
            return false
        end
        return true
    end)
end
