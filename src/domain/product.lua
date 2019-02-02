products = products or {}

Product = {
    --- create a new Product
    --- @param self
    --- @param name string
    --- @param config table
    ---   @field id string|nil
    ---   @field size number (default: `1`)
    --- @return Product
    new = function(self, name, config)
        if not isString(name) then error("Expected name to be a string, but got " .. typeInspect(name)) end
        config = config or {}
        if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config)) end
        config.id = config.id or Util.randomUuid()
        if not isString(config.id) then error("Expected id to be a string, but got " .. typeInspect(config.id)) end
        config.size = config.size or 1
        if not isNumber(config.size) then error("Expected size to be numeric, but got " .. typeInspect(config.size)) end

        return {
            --- get the id of the product
            --- @param self
            --- @return string
            getId = function(self) return config.id end,

            --- get the name of the product
            --- @param self
            --- @return string
            getName = function(self) return name end,

            --- get the size of this product
            --- @param self
            --- @return number
            getSize = function(self) return config.size end,
        }
    end,

    --- accepts string or product and returns the id
    --- @internal
    --- @param self
    --- @param product Product
    --- @return string
    toId = function(self, product)
        if isString(product) then
            return product
        elseif Product:isProduct(product) then
            return product.getId()
        else
            error("The given object does not look like a product.", 3)
        end
    end,

    --- check if the given thing is a product
    --- @param self
    --- @param thing any
    --- @return boolean
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