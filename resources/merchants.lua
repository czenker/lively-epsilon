buyingPrice = function(product)
    local price = product.basePrice * (math.random() * 0.1 + 1.1)
    return function(station, seller)
        local factor = 1
        if isEeShipTemplateBased(station) and isEeShipTemplateBased(seller) then
            if station:isFriendly(seller) then
                factor = 1.1
            else
                factor = 1
            end
        end
        return price * factor
    end
end

sellingPrice = function(product)
    local price = product.basePrice * (math.random() * 0.1 + 0.8)
    return function(station, buyer)
        local factor = 1
        if isEeShipTemplateBased(station) and isEeShipTemplateBased(buyer) then
            if station:isFriendly(buyer) then
                factor = 0.9
            else
                factor = 1
            end
        end
        return price * factor
    end
end