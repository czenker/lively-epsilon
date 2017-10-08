ShipTemplateBased = ShipTemplateBased or {}
-- a storage system where one room exists for each product stored
ShipTemplateBased.withStorageRooms = function (self, spaceObject, storages)
    if not isEeShipTemplateBased(spaceObject) then
        error ("Expected a shipTemplateBased object but got " .. type(spaceObject), 2)
    end

    if hasStorage(spaceObject) then
        -- @TODO: ???
        error("can not reconfigure storage", 2)
    end

    if type(storages) ~= "table" then
        error("Expected a table with storage configuration, but got " .. type(storages), 2)
    end

    local storage = {}

    for product, maxStorage in pairs(storages) do
        product = Product.toId(product)

        storage[product] = {
            storage = 0,
            maxStorage = maxStorage
        }
    end

    local function getStorage(product)
        product = Product.toId(product)
        return storage[product]
    end

    --- get the storage level of the product
    -- @param self
    -- @param product the product to get the storage level of
    -- @return the storage level of the product or nil if the product can not be stored
    spaceObject.getProductStorage = function(self, product)
        local storage = getStorage(product)

        if storage == nil then
            return nil
        else
            return storage.storage
        end
    end

    --- get the maximum storage level of the product
    -- @param self
    -- @param product the product to get the maximum storage level of
    -- @return the maximum storage level of the product or nil if the product can not be stored
    spaceObject.getMaxProductStorage = function(self, product)
        local storage = getStorage(product)

        if storage == nil then
            return nil
        else
            return storage.maxStorage
        end
    end

    --- get the empty storage level of the product
    -- @param self
    -- @param product the product to get the empty storage level of
    -- @return the empty storage level of the product or nil if the product can not be stored
    spaceObject.getEmptyProductStorage = function(self, product)
        local storage = getStorage(product)

        if storage == nil then
            return nil
        else
            return storage.maxStorage - storage.storage
        end
    end

    --- modify the storage levels of a product
    -- it will fail silently if the product can not be stored and will create products out of thin vacuum or discard products when storage is full.
    -- @param self
    -- @param product the product to change the storage level of
    spaceObject.modifyProductStorage = function(self, product, amount)
        local storage = getStorage(product)

        if storage ~= nil then
            storage.storage = storage.storage + amount
            if storage.storage > storage.maxStorage then storage.storage = storage.maxStorage end
            if storage.storage < 0 then storage.storage = 0 end
        end
    end

    --- returns true if the given product can be stored
    -- @param self
    -- @param product
    -- @return boolean
    spaceObject.canStoreProduct = function (self, product)
        local storage = getStorage(product)
        return storage ~= nil and storage.maxStorage > 0
    end

    return self
end