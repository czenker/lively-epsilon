products = products or {}

Product = {
    new = function(self, name, id)
        if not isString(name) then error("Expected name to be a string, but got " .. type(name)) end
        id = id or Util.randomUuid()
        if not isString(id) then error("Expected id to be a string, but got " .. type(id)) end

        return {
            getId = function(self) return id end,
            getName = function(self) return name end,
        }
    end,

    --- accepts string or product and returns the id
    -- @param product
    -- @return string
    toId = function(self, product)
        if isString(product) then
            return product
        elseif Product.isProduct(product) then
            return product.getId()
        else
            error("The given object does not look like a product.", 3)
        end
    end,

    isProduct = function(thing)
        return isTable(thing) and
                isFunction(thing.getId) and
                isFunction(thing.getName)
    end
}

setmetatable(Product,{
    __index = Generic
})