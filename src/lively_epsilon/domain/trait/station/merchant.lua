Station = Station or {}
-- enhances a station with the possibility to buy and sell products
Station.withMerchant = function (self, station, configuration)
    if not isEeStation(station) then
        error ("Expected a station but got " .. type(station), 2)
    end
    if not Station:hasStorage(station) then
        error ("station " .. station:getCallSign() .. " needs to have a storage configured", 2)
    end

    if Station:hasMerchant(station) then
        -- @TODO: ???
        error("can not reconfigure merchant", 2)
    end

    if type(configuration) ~= "table" then
        error("Expected a table with configuration, but got " .. type(configuration), 2)
    end

    local merchant = {}

    for product, conf in pairs(configuration) do
        local productId = Product:toId(product)

        if not station:canStoreProduct(product) then
            error("there is no storage for " .. product .. " configured in " .. station:getCallSign(), 2)
        end

        if conf.buyingPrice == nil and conf.sellingPrice == nil then
            error("configuration for " .. product .. " either needs a buyingPrice or a sellingPrice", 3)
        elseif conf.buyingPrice ~= nil and conf.sellingPrice ~= nil then
            error("configuration for " .. product .. " can only have a buyingPrice or a sellingPrice - not both", 3)
        elseif conf.buyingPrice ~= nil then
            merchant[productId] = {
                product = product,
                buyingPrice = conf.buyingPrice,
                buyingLimit = conf.buyingLimit or nil
            }
        elseif conf.sellingPrice ~= nil then
            merchant[productId] = {
                product = product,
                sellingPrice = conf.sellingPrice,
                sellingLimit = conf.sellingLimit or nil
            }
        end
    end

    local function getBuying(product)
        product = Product:toId(product)
        if merchant[product] == nil or type(merchant[product].buyingPrice) == "nil" then
            return nil
        else
            return merchant[product]
        end
    end

    local function getSelling(product)
        product = Product:toId(product)
        if merchant[product] == nil or type(merchant[product].sellingPrice) == "nil" then
            return nil
        else
            return merchant[product]
        end
    end

    station.getProductBuyingPrice = function (self, product)
        local buying = getBuying(product)

        if buying == nil then
            return nil
        elseif type(buying.buyingPrice) == "function" then
            return buying.buyingPrice(station)
        else
            return buying.buyingPrice
        end
    end

    station.getMaxProductBuying = function (self, product)
        local buying = getBuying(product)

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

    station.isBuyingProduct = function (self, product)
        return self:getProductBuyingPrice(product) ~= nil
    end

    station.getProductsBought = function (self)
        local products = {}

        for productId, merchant in pairs(merchant) do
            if self:isBuyingProduct(productId) then
                products[productId] = merchant.product
            end
        end

        return products
    end

    station.getProductSellingPrice = function (self, product)
        local selling = getSelling(product)

        if selling == nil then
            return nil
        elseif type(selling.sellingPrice) == "function" then
            return selling.sellingPrice(station)
        else
            return selling.sellingPrice
        end
    end

    station.getMaxProductSelling = function (self, product)
        local selling = getSelling(product)

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

    station.isSellingProduct = function (self, product)
        return self:getProductSellingPrice(product) ~= nil
    end

    station.getProductsSold = function (self)
        local products = {}

        for productId, merchant in pairs(merchant) do
            if self:isSellingProduct(productId) then
                products[productId] = merchant.product
            end
        end

        return products
    end

end

--- checks if the given object has a merchant that buys or sells stuff
-- @param station
-- @return boolean
Station.hasMerchant = function(self, station)
    return isFunction(station.getProductBuyingPrice) and
            isFunction(station.getMaxProductBuying) and
            isFunction(station.isBuyingProduct) and
            isFunction(station.getProductsBought) and
            isFunction(station.getProductSellingPrice) and
            isFunction(station.getMaxProductSelling) and
            isFunction(station.isSellingProduct) and
            isFunction(station.getProductsSold)
end