Player = Player or {}

local function isWeapon(product)
    return product:getId() == "hvli" or product:getId() == "homing" or product:getId() == "mine" or product:getId() == "emp" or product:getId() == "nuke"
end

Player.withStorage = function(self, player, config)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if Player:hasStorage(player) then error("Player already has a storage" .. type(player), 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    config.maxStorage = config.maxStorage or 100

    local maxStorage = config.maxStorage
    -- key: product
    -- value: storage amount
    local storage = {}

    player.getStoredProducts = function(self)
        local ret = {}
        local i = 1
        for product, amount in pairs(storage) do
            ret[i] = product
            i = i+1
        end
        return ret
    end

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

    player.getMaxProductStorage = function(self, product)
        if not Product:isProduct(product) then error("Expected a product, but got " .. typeInspect(product)) end

        if isWeapon(product) then
            return player:getWeaponStorageMax(product:getId())
        else
            return math.min(self:getEmptyProductStorage(product) + self:getProductStorage(product), maxStorage)
        end
    end

    player.getEmptyProductStorage = function(self, product)
        if not Product:isProduct(product) then error("Expected a product, but got " .. typeInspect(product)) end

        if isWeapon(product) then
            return player:getWeaponStorageMax(product:getId()) - player:getWeaponStorage(product:getId())
        else
            return math.floor(self:getEmptyStorageSpace() / product:getSize())
        end
    end

    player.modifyProductStorage = function(self, product, amount)
        if not Product:isProduct(product) then error("Expected a product, but got " .. typeInspect(product)) end
        if not isNumber(amount) then error("Expected a number, but got " .. typeInspect(amount)) end

        if isWeapon(product) then
            player:setWeaponStorage(product:getId(), player:getWeaponStorage(product:getId()) + amount)
        else
            storage[product] = (storage[product] or 0) + amount
            if storage[product] <= 0 then storage[product] = nil end
        end
    end

    player.getEmptyStorageSpace = function(self)
        local free = maxStorage
        for product, amount in pairs(storage) do
            free = free - amount * product.getSize()
        end
        return math.max(free, 0)
    end

    player.getMaxStorageSpace = function(self)
        return maxStorage
    end

    player.setMaxStorageSpace = function(self, number)
        maxStorage = number
    end

    player.getStorageSpace = function(self)
        local sum = 0
        for product, amount in pairs(storage) do
            sum = sum + amount * product.getSize()
        end
        return sum
    end
end

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