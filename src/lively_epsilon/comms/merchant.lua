Comms = Comms or {}

Comms.merchantFactory = function(self, config)
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    if not isString(config.label) and not isFunction(config.label) then error("expected label to be a string or function, but got " .. type(config.label), 2) end
    if not isFunction(config.mainScreen) then error("expected mainScreen to be a function, but got " .. type(config.mainScreen), 2) end
    if not isFunction(config.buyScreen) then error("expected buyScreen to be a function, but got " .. type(config.buyScreen), 2) end
    if not isFunction(config.buyProductScreen) then error("expected buyProductScreen to be a function, but got " .. type(config.buyProductScreen), 2) end
    if not isFunction(config.sellScreen) then error("expected sellScreen to be a function, but got " .. type(config.sellScreen), 2) end
    if not isFunction(config.sellProductScreen) then error("expected sellProductScreen to be a function, but got " .. type(config.sellProductScreen), 2) end

    local mainMenu
    local buyMenu
    local buyProductMenu
    local sellMenu
    local sellProductMenu

    local defaultCallbackConfig

    local formatBoughtProduct = function(product, station, player)
        return {
            product = product,
            price = station:getProductBuyingPrice(product),
            maxAmount = station:getMaxProductBuying(product),
            link = buyProductMenu(product),
            linkAmount = function(amount) buyProductMenu(product, amount) end,
        }
    end

    local formatBoughtProducts = function(station, player)
        local ret = {}
        for _, product in pairs(station:getProductsBought()) do
            ret[product:getId()] = formatBoughtProduct(product, station, player)
        end
        return ret
    end

    local formatSoldProduct = function(product, station, player)
        return {
            product = product,
            price = station:getProductSellingPrice(product),
            maxAmount = station:getMaxProductSelling(product),
            link = sellProductMenu(product),
            linkAmount = function(amount) sellProductMenu(product, amount) end,
        }
    end

    local formatSoldProducts = function(station, player)
        local ret = {}
        for _, product in pairs(station:getProductsSold()) do
            ret[product:getId()] = formatSoldProduct(product, station, player)
        end
        return ret
    end

    mainMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config.mainScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            buying = formatBoughtProducts(comms_target, comms_source),
            selling = formatSoldProducts(comms_target, comms_source),
        }))
        return screen
    end

    buyMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config.buyScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            buying = formatBoughtProducts(comms_target, comms_source),
        }))
        return screen
    end

    buyProductMenu = function(product, amount)
        amount = amount or 0
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            config.buyProductScreen(screen, comms_target, comms_source, Util.mergeTables(
                defaultCallbackConfig,
                formatBoughtProduct(product, comms_target, comms_source),
                {amount = amount}
            ))
            return screen
        end
    end

    sellMenu = function(comms_target, comms_source)
        local screen = Comms.screen()
        config.sellScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            selling = formatSoldProducts(comms_target, comms_source),
        }))
        return screen
    end

    sellProductMenu = function(product, amount)
        amount = amount or 0
        return function(comms_target, comms_source)
            local screen = Comms.screen()
            config.sellProductScreen(screen, comms_target, comms_source, Util.mergeTables(
                defaultCallbackConfig,
                formatSoldProduct(product, comms_target, comms_source),
                {amount = amount}
            ))
            return screen
        end
    end


    -- don't ask me why, but if this is defined with its declaration it will be an empty table in the callbacks...
    defaultCallbackConfig = {
        linkToMainScreen = mainMenu,
        linkToBuyScreen = buyMenu,
        linkToSellScreen = sellMenu,
    }

    return Comms.reply(config.label, mainMenu)
end
