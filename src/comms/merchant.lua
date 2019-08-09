Comms = Comms or {}

--- create comms for a merchant
--- @param self
--- @param config table
---   @field label string|function the label that leads to the merchant in comms
---   @field mainScreen function gets a `screen`, `comms_target`, `comms_source` and an `info`. Should manipulate the screen to contain human readable text.
---   @field buyScreen function gets a `screen`, `comms_target`, `comms_source` and an `info`. Should manipulate the screen to contain human readable text.
---   @field buyProductScreen function gets a `screen`, `comms_target`, `comms_source` and an `info`. Should manipulate the screen to contain human readable text.
---   @field buyProductConfirmScreen function gets a `screen`, `comms_target`, `comms_source` and an `info`. Should manipulate the screen to contain human readable text.
---   @field sellScreen function gets a `screen`, `comms_target`, `comms_source` and an `info`. Should manipulate the screen to contain human readable text.
---   @field sellProductScreen function gets a `screen`, `comms_target`, `comms_source` and an `info`. Should manipulate the screen to contain human readable text.
---   @field sellProductConfirmScreen function gets a `screen`, `comms_target`, `comms_source` and an `info`. Should manipulate the screen to contain human readable text.
---   @field displayCondition nil|function  gets `station` and `comms_source`. Should return a `boolean`.
Comms.merchantFactory = function(self, config)
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    if not isString(config.label) and not isFunction(config.label) then error("expected label to be a string or function, but got " .. typeInspect(config.label), 2) end
    if not isFunction(config.mainScreen) then error("expected mainScreen to be a function, but got " .. typeInspect(config.mainScreen), 2) end
    if not isFunction(config.buyScreen) then error("expected buyScreen to be a function, but got " .. typeInspect(config.buyScreen), 2) end
    if not isFunction(config.buyProductScreen) then error("expected buyProductScreen to be a function, but got " .. typeInspect(config.buyProductScreen), 2) end
    if not isFunction(config.buyProductConfirmScreen) then error("expected buyProductConfirmScreen to be a function, but got " .. typeInspect(config.buyProductConfirmScreen), 2) end
    if not isFunction(config.sellScreen) then error("expected sellScreen to be a function, but got " .. typeInspect(config.sellScreen), 2) end
    if not isFunction(config.sellProductScreen) then error("expected sellProductScreen to be a function, but got " .. typeInspect(config.sellProductScreen), 2) end
    if not isFunction(config.sellProductConfirmScreen) then error("expected sellProductConfirmScreen to be a function, but got " .. typeInspect(config.sellProductConfirmScreen), 2) end
    if not isNil(config.displayCondition) and not isFunction(config.displayCondition) then error("expected displayCondition to be a function, but got " .. typeInspect(config.displayCondition), 2) end

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
            table.insert(ret, formatBoughtProduct(product, station, player))
        end
        table.sort(ret, function(a, b) return a.product:getName() < b.product:getName() end)
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
            table.insert(ret, formatSoldProduct(product, station, player))
        end
        table.sort(ret, function(a, b) return a.product:getName() < b.product:getName() end)
        return ret
    end

    mainMenu = function(comms_target, comms_source)
        local screen = Comms:newScreen()
        config.mainScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            buying = formatBoughtProducts(comms_target, comms_source),
            selling = formatSoldProducts(comms_target, comms_source),
        }))
        return screen
    end

    buyMenu = function(comms_target, comms_source)
        local screen = Comms:newScreen()
        config.buyScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            buying = formatBoughtProducts(comms_target, comms_source),
        }))
        return screen
    end

    buyProductMenu = function(product, amount)
        amount = amount or 0
        return function(comms_target, comms_source)
            local screen = Comms:newScreen()
            local info = formatBoughtProduct(product, comms_target, comms_source)
            config.buyProductScreen(screen, comms_target, comms_source, Util.mergeTables(
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
            local screen = Comms:newScreen()
            local info = formatBoughtProduct(product, comms_target, comms_source)
            amount = math.min(
                amount or 9999,
                info.stationAmount,
                info.playerAmount
            )
            local success = config.buyProductConfirmScreen(screen, comms_target, comms_source, Util.mergeTables(
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
        local screen = Comms:newScreen()
        config.sellScreen(screen, comms_target, comms_source, Util.mergeTables(defaultCallbackConfig, {
            selling = formatSoldProducts(comms_target, comms_source),
        }))
        return screen
    end

    sellProductMenu = function(product, amount)
        amount = amount or 0
        return function(comms_target, comms_source)
            local screen = Comms:newScreen()
            local info = formatSoldProduct(product, comms_target, comms_source)
            config.sellProductScreen(screen, comms_target, comms_source, Util.mergeTables(
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
            local screen = Comms:newScreen()
            local info = formatSoldProduct(product, comms_target, comms_source)
            amount = math.min(
                amount or 9999,
                info.stationAmount,
                info.playerAmount,
                info.affordableAmount
            )
            local success = config.sellProductConfirmScreen(screen, comms_target, comms_source, Util.mergeTables(
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

    return Comms:newReply(config.label, mainMenu, function(comms_target, comms_source)
        if not Station:hasMerchant(comms_target) or not Player:hasStorage(comms_source) then
            logInfo("not displaying merchant in Comms, because target has no merchant.")
            return false
        elseif userCallback(config.displayCondition, comms_target, comms_source) == false then
            return false
        end
        return true
    end)
end
