Product = {
    --- accepts string or product and returns the id
    -- @param product
    -- @return string
    toId = function(product)
        if isString(product) then
            return product
        elseif Product.isProduct(product) then
            return product.id
        else
            error("The given object does not look like a product.", 3)
        end
    end,

    isProduct = function(thing)
        return isTable(thing) and isString(thing.id) and isString(thing.name)
    end
}