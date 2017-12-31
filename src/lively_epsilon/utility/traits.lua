--- checks if the given object does have a storage
-- @param station
-- @return boolean
function hasStorage(station)
    return isFunction(station.getProductStorage) and
            isFunction(station.getMaxProductStorage) and
            isFunction(station.getEmptyProductStorage) and
            isFunction(station.modifyProductStorage) and
            isFunction(station.canStoreProduct)
end

--- checks if the given object is able to offer missions
-- @param station
-- @return boolean
function hasMissions(station)
    return isFunction(station.addMission) and
            isFunction(station.removeMission) and
            isFunction(station.clearMissions) and
            isFunction(station.getMissions) and
            isFunction(station.hasMissions)
end

--- checks if the given object has a production configured
-- @param station
-- @return boolean
function hasProduction(station)
    return isFunction(station.getProducedProducts) and
            isFunction(station.getConsumedProducts)
end

--- checks if the given object has a merchant that buys or sells stuff
-- @param station
-- @return boolean
function hasMerchant(station)
    return isFunction(station.getProductBuyingPrice) and
            isFunction(station.getMaxProductBuying) and
            isFunction(station.isBuyingProduct) and
            isFunction(station.getProductsBought) and
            isFunction(station.getProductSellingPrice) and
            isFunction(station.getMaxProductSelling) and
            isFunction(station.isSellingProduct) and
            isFunction(station.getProductsSold)
end

function hasComms(station)
    return isFunction(station.getHailText) and
        isFunction(station.setHailText)
end