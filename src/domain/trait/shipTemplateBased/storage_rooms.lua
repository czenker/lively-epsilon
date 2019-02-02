ShipTemplateBased = ShipTemplateBased or {}

--- Add a storage.
---
--- This is a storage system where one room exists for each product stored. So storing one product does not take space away from another storage space.
--- @param self
--- @param spaceObject ShipTemplateBased
--- @param storages table[Product,number] configure the storage space for each product
--- @return ShipTemplateBased
ShipTemplateBased.withStorageRooms = function (self, spaceObject, storages)
    if not isEeShipTemplateBased(spaceObject) then
        error ("Expected a shipTemplateBased object but got " .. typeInspect(spaceObject), 2)
    end

    if ShipTemplateBased:hasStorage(spaceObject) then
        -- @TODO: ???
        error("can not reconfigure storage", 2)
    end

    if type(storages) ~= "table" then
        error("Expected a table with storage configuration, but got " .. typeInspect(storages), 2)
    end

    local storage = {}

    for product, maxStorage in pairs(storages) do
        product = Product:toId(product)

        storage[product] = {
            storage = 0,
            maxStorage = maxStorage
        }
    end

    local function getStorage(product)
        product = Product:toId(product)
        return storage[product]
    end

    --- get the storage level of the product
    --- @param self
    --- @param product Product the product to get the storage level of
    --- @return number|nil the storage level of the product or `nil` if the product can not be stored
    spaceObject.getProductStorage = function(self, product)
        local storage = getStorage(product)

        if storage == nil then
            return nil
        else
            return storage.storage
        end
    end

    --- get the maximum storage level of the product
    --- @param self
    --- @param product Product the product to get the maximum storage level of
    --- @return number|nil the maximum storage level of the product or `nil` if the product can not be stored
    spaceObject.getMaxProductStorage = function(self, product)
        local storage = getStorage(product)

        if storage == nil then
            return nil
        else
            return storage.maxStorage
        end
    end

    --- get the empty storage level of the product
    --- @param self
    --- @param product Product the product to get the empty storage level of
    --- @return number|nil the empty storage level of the product or `nil` if the product can not be stored
    spaceObject.getEmptyProductStorage = function(self, product)
        local storage = getStorage(product)

        if storage == nil then
            return nil
        else
            return storage.maxStorage - storage.storage
        end
    end

    --- modify the storage levels of a product
    --- it will fail silently if the product can not be stored and will create products out of thin vacuum or discard products when storage is full.
    --- @param self
    --- @param product Product the product to change the storage level of
    --- @param amount number positive number to add to the storage, negative number to remove
    --- @return ShipTemplateBased
    spaceObject.modifyProductStorage = function(self, product, amount)
        local storage = getStorage(product)

        if storage ~= nil then
            storage.storage = storage.storage + amount
            if storage.storage > storage.maxStorage then storage.storage = storage.maxStorage end
            if storage.storage < 0 then storage.storage = 0 end
        end

        return self
    end

    --- returns true if the given product can be stored
    --- @param self
    --- @param product Product
    --- @return boolean
    spaceObject.canStoreProduct = function (self, product)
        local storage = getStorage(product)
        return storage ~= nil and storage.maxStorage > 0
    end

    return spaceObject
end

--- checks if the given object does have a storage
--- @param self
--- @param station any
--- @return boolean
ShipTemplateBased.hasStorage = function(self, station)
    return isTable(station) and
        isFunction(station.getProductStorage) and
        isFunction(station.getMaxProductStorage) and
        isFunction(station.getEmptyProductStorage) and
        isFunction(station.modifyProductStorage) and
        isFunction(station.canStoreProduct)
end