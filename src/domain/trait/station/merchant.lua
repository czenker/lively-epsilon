Station = Station or {}
--- enhances a station with the possibility to buy and sell products
--- @param self
--- @param station SpaceStation
--- @param configuration table[Product,table]
---   @field buyingPrice number|function|nil
---   @field sellingPrice number|function|nil
--- @return SpaceStation
Station.withMerchant = function (self, station, configuration)
    if not isEeStation(station) then
        error ("Expected a station but got " .. typeInspect(station), 2)
    end
    if not Station:hasStorage(station) then
        error ("station " .. station:getCallSign() .. " needs to have a storage configured", 2)
    end

    if Station:hasMerchant(station) then
        -- @TODO: ???
        error("can not reconfigure merchant", 2)
    end

    if type(configuration) ~= "table" then
        error("Expected a table with configuration, but got " .. typeInspect(configuration), 2)
    end

    local merchant = {}

    for product, conf in pairs(configuration) do
        local productId = Product:toId(product)

        if not station:canStoreProduct(product) then
            error("there is no storage for " .. productId .. " configured in " .. station:getCallSign(), 2)
        end

        -- getRestocksScanProbes() is a new method. We do not want to fail on older versions - so keep the check for now.
        if productId == "scanProbe" and isFunction(station.getRestocksScanProbes) and station:getRestocksScanProbes() then
            logWarning(string.format("Station \"%s\" trades with scan probes, but also restocks them on player ships automatically for free. Consider setting station:setRestocksScanProbes(false) to disable automatic scan probe restocking.", station:getCallSign()))
        end

        if conf.buyingPrice == nil and conf.sellingPrice == nil then
            error("configuration for " .. Product:toId(product) .. " either needs a buyingPrice or a sellingPrice", 3)
        else
            merchant[productId] = {
                product = product,
            }
            if conf.buyingPrice ~= nil then
                local buyingPriceFunc
                if isNumber(conf.buyingPrice) or isNil(conf.buyingPrice) then
                    buyingPriceFunc = function() return conf.buyingPrice end
                elseif isFunction(conf.buyingPrice) then
                    buyingPriceFunc = conf.buyingPrice
                else
                    error("buyingPrice needs to be a number or a function", 5)
                end
                merchant[productId].buyingPrice = buyingPriceFunc
                merchant[productId].buyingLimit = conf.buyingLimit or nil
            end
            if conf.sellingPrice ~= nil then
                local sellingPriceFunc
                if isNumber(conf.sellingPrice) or isNil(conf.sellingPrice) then
                    sellingPriceFunc = function() return conf.sellingPrice end
                elseif isFunction(conf.sellingPrice) then
                    sellingPriceFunc = conf.sellingPrice
                else
                    error("sellingPrice needs to be a number or a function", 5)
                end
                merchant[productId].sellingPrice = sellingPriceFunc
                merchant[productId].sellingLimit = conf.sellingLimit or nil
            end
        end
    end

    local function getBuying(product, seller)
        product = Product:toId(product)
        local conf = merchant[product]
        if conf == nil or isNil(conf.buyingPrice) or isNil(conf.buyingPrice(station, seller)) then
            return nil
        else
            return conf
        end
    end

    local function getSelling(product, buyer)
        product = Product:toId(product)
        local conf = merchant[product]
        if conf == nil or isNil(conf.sellingPrice) or isNil(conf.sellingPrice(station, buyer)) then
            return nil
        else
            return conf
        end
    end

    --- get the price the station is buying this product at
    --- @param self
    --- @param product Product
    --- @param seller SpaceShip
    --- @return nil|number
    station.getProductBuyingPrice = function (self, product, seller)
        local buying = getBuying(product, seller)

        if buying == nil then
            return nil
        elseif type(buying.buyingPrice) == "function" then
            return buying.buyingPrice(station, seller)
        else
            return buying.buyingPrice
        end
    end

    --- get the maximum number of units the station would buy
    --- @param self
    --- @param product Product
    --- @param seller SpaceShip
    --- @return number|nil
    station.getMaxProductBuying = function (self, product, seller)
        local buying = getBuying(product, seller)

        if buying == nil then
            return nil
        else
            local limit = self:getMaxProductStorage(product)
            if isNumber(buying.buyingLimit) then
                limit = buying.buyingLimit
            end

            if limit <= self:getProductStorage(product) then
                return 0
            else
                return limit - self:getProductStorage(product)
            end
        end
    end

    --- check if the station is buying the product
    --- @param self
    --- @param product Product
    --- @param seller SpaceShip
    --- @return boolean
    station.isBuyingProduct = function (self, product, seller)
        return self:getProductBuyingPrice(product, seller) ~= nil
    end

    --- get a list of all products the station is buying
    --- @param self
    --- @param seller SpaceShip
    --- @return table[Product]
    station.getProductsBought = function (self, seller)
        local products = {}

        for productId, merchant in pairs(merchant) do
            if self:isBuyingProduct(productId, seller) then
                products[productId] = merchant.product
            end
        end

        return products
    end

    --- get the price the station is selling this product at
    --- @param self
    --- @param product Product
    --- @param buyer SpaceShip
    --- @return nil|number
    station.getProductSellingPrice = function (self, product, buyer)
        local selling = getSelling(product, buyer)

        if selling == nil then
            return nil
        elseif type(selling.sellingPrice) == "function" then
            return selling.sellingPrice(station, buyer)
        else
            return selling.sellingPrice
        end
    end

    --- get the maximum number of units the station would sell
    --- @param self
    --- @param product Product
    --- @param buyer SpaceShip
    --- @return number|nil
    station.getMaxProductSelling = function (self, product, buyer)
        local selling = getSelling(product, buyer)

        if selling == nil then
            return nil
        else
            local limit = 0
            if isNumber(selling.sellingLimit) then
                limit = selling.sellingLimit
            end

            if limit >= self:getProductStorage(product) then
                return 0
            else
                return self:getProductStorage(product) - limit
            end
        end
    end

    --- check if the station is selling the product
    --- @param self
    --- @param product Product
    --- @param buyer SpaceShip
    --- @return boolean
    station.isSellingProduct = function (self, product, buyer)
        return self:getProductSellingPrice(product, buyer) ~= nil
    end

    --- get a list of all products the station is selling
    --- @param self
    --- @param buyer SpaceShip
    --- @return table[Product]
    station.getProductsSold = function (self, buyer)
        local products = {}

        for productId, merchant in pairs(merchant) do
            if self:isSellingProduct(productId, buyer) then
                products[productId] = merchant.product
            end
        end

        return products
    end

    return station

end

--- checks if the given object has a merchant that buys or sells stuff
--- @param self
--- @param station any
--- @return boolean
Station.hasMerchant = function(self, station)
    return isTable(station) and
            isFunction(station.getProductBuyingPrice) and
            isFunction(station.getMaxProductBuying) and
            isFunction(station.isBuyingProduct) and
            isFunction(station.getProductsBought) and
            isFunction(station.getProductSellingPrice) and
            isFunction(station.getMaxProductSelling) and
            isFunction(station.isSellingProduct) and
            isFunction(station.getProductsSold)
end