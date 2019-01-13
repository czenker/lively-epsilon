Player = Player or {}

-- config
-- - label
-- - title
-- - labelUsedStorage
-- - emptyStorage
Player.withStorageDisplay = function(self, player, config)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. type(player), 2) end
    if not Player:hasStorage(player) then error("Player should have a storage", 2) end
    if not Player:hasMenu(player) then error("Expected player " .. player:getCallSign() .. " to have menus enabled, but it does not", 2) end
    if Player:hasStorageDisplay(player) then error("Player already has a storage display", 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    if not isString(config.label) then error("Expected label to be a string, but got " .. type(config.label), 2) end
    if not isString(config.title) then error("Expected title to be a string, but got " .. type(config.title), 2) end
    if not isString(config.labelUsedStorage) then error("Expected labelUsedStorage to be a string, but got " .. type(config.labelUsedStorage), 2) end
    if not isString(config.emptyStorage) then error("Expected emptyStorage to be a string, but got " .. type(config.emptyStorage), 2) end

    -- The integration will probably change, because I think having some kind of menu structure might be the better option
    -- And it should be possible to translate or modify this. :)

    player:addEngineeringMenuItem(Menu:newItem(config.label, function()
        local text = config.title .. "\n--------------------------\n"

        text = text .. config.labelUsedStorage .. ": " .. player:getStorageSpace() .. "/" .. player:getMaxStorageSpace() .. "\n\n"

        local products = player:getStoredProducts()
        if Util.size(products) == 0 then
            text = text .. config.emptyStorage.. "\n"
        else
            for _,product in pairs(products) do
                text = text .. " * ".. player:getProductStorage(product) .. " x " .. product:getName() .. "\n"
            end
        end

        return text
    end))

    player.storageDisplayActive = true

end

Player.hasStorageDisplay = function(self, player)
    return isTable(player) and player.storageDisplayActive
end