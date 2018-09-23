products = products or {}

Product = {
    new = function(self, name, config)
        if not isString(name) then error("Expected name to be a string, but got " .. type(name)) end
        config = config or {}
        if not isTable(config) then error("Expected config to be a table, but got " .. type(config)) end
        config.id = config.id or Util.randomUuid()
        if not isString(config.id) then error("Expected id to be a string, but got " .. type(config.id)) end
        config.size = config.size or 1
        if not isNumber(config.size) then error("Expected size to be numeric, but got " .. type(config.size)) end

        return {
            getId = function(self) return config.id end,
            getName = function(self) return name end,
            getSize = function(self) return config.size end,
        }
    end,

    --- accepts string or product and returns the id
    -- @param product
    -- @return string
    toId = function(self, product)
        if isString(product) then
            return product
        elseif Product:isProduct(product) then
            return product.getId()
        else
            error("The given object does not look like a product.", 3)
        end
    end,

    isProduct = function(self, thing)
        return isTable(thing) and
                isFunction(thing.getId) and
                isFunction(thing.getName) and
                isFunction(thing.getSize)
    end
}

setmetatable(Product,{
    __index = Generic
})