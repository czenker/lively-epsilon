Player = Player or {}

local function isWeapon(product)
    return product:getId() == "hvli" or product:getId() == "homing" or product:getId() == "mine" or product:getId() == "emp" or product:getId() == "nuke"
end

--- configure storage for a player
--- @param self
--- @param player PlayerSpaceship
--- @param config table
--- @return PlayerSpaceship
Player.withStorage = function(self, player, config)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if Player:hasStorage(player) then error("Player " .. player:getCallSign() .. " already has a storage", 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    config.maxStorage = config.maxStorage or 100

    local maxStorage = config.maxStorage
    -- key: product
    -- value: storage amount
    local storage = {}

    --- get a list of all products currently stored
    --- @param self
    --- @return table[Product,number]
    player.getStoredProducts = function(self)
        local ret = {}
        local i = 1
        for product, amount in pairs(storage) do
            ret[i] = product
            i = i+1
        end
        return ret
    end

    --- get the storage level of a given product
    --- @param self
    --- @param product Product
    --- @return number
    player.getProductStorage = function(self, product)
        if not Product:isProduct(product) then error("Expected a product, but got " .. typeInspect(product)) end
        if isWeapon(product) then
            return player:getWeaponStorage(product:getId())
        elseif storage[product] == nil then
            return 0
        else
            return storage[product]
        end
    end

    --- get the maximum amount the player can store
    --- @param self
    --- @param product Product
    --- @return number
    player.getMaxProductStorage = function(self, product)
        if not Product:isProduct(product) then error("Expected a product, but got " .. typeInspect(product)) end

        if isWeapon(product) then
            return player:getWeaponStorageMax(product:getId())
        else
            return math.min(self:getEmptyProductStorage(product) + self:getProductStorage(product), maxStorage)
        end
    end

    --- get the free space to store a product
    --- @param self
    --- @param product Product
    --- @return number
    player.getEmptyProductStorage = function(self, product)
        if not Product:isProduct(product) then error("Expected a product, but got " .. typeInspect(product)) end

        if isWeapon(product) then
            return player:getWeaponStorageMax(product:getId()) - player:getWeaponStorage(product:getId())
        else
            return math.floor(self:getEmptyStorageSpace() / product:getSize())
        end
    end

    --- change the amount of stored product
    --- @param self
    --- @param product Product
    --- @param amount number positive or negative number to add or remove
    --- @return PlayerSpaceship
    player.modifyProductStorage = function(self, product, amount)
        if not Product:isProduct(product) then error("Expected a product, but got " .. typeInspect(product)) end
        if not isNumber(amount) then error("Expected a number, but got " .. typeInspect(amount)) end

        if isWeapon(product) then
            player:setWeaponStorage(product:getId(), player:getWeaponStorage(product:getId()) + amount)
        else
            storage[product] = (storage[product] or 0) + amount
            if storage[product] <= 0 then storage[product] = nil end
        end
        return self
    end

    --- get the total empty storage space
    --- @param self
    --- @return number
    player.getEmptyStorageSpace = function(self)
        local free = maxStorage
        for product, amount in pairs(storage) do
            free = free - amount * product.getSize()
        end
        return math.max(free, 0)
    end

    --- get the maximum storage space
    --- @param self
    --- @return number
    player.getMaxStorageSpace = function(self)
        return maxStorage
    end

    --- set the maximum storage space
    --- @param self
    --- @param number number
    --- @return PlayerSpaceship
    player.setMaxStorageSpace = function(self, number)
        maxStorage = number
        return self
    end

    --- get the used storage space
    --- @param self
    --- @return number
    player.getStorageSpace = function(self)
        local sum = 0
        for product, amount in pairs(storage) do
            sum = sum + amount * product.getSize()
        end
        return sum
    end

    return player
end

--- check if the player has a storage
--- @param self
--- @param player PlayerSpaceship
Player.hasStorage = function(self, player)
    return isTable(player) and
            isFunction(player.getStoredProducts) and
            isFunction(player.getProductStorage) and
            isFunction(player.getMaxProductStorage) and
            isFunction(player.getEmptyProductStorage) and
            isFunction(player.modifyProductStorage) and
            isFunction(player.getEmptyStorageSpace) and
            isFunction(player.getMaxStorageSpace) and
            isFunction(player.setMaxStorageSpace) and
            isFunction(player.getStorageSpace)
end