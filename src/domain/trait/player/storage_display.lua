Player = Player or {}

--- add a storage display for the engineering station
--- @deprecated The integration will probably change, because I think having some kind of menu structure might be the better option
--- @param self
--- @param player PlayerSpaceship
--- @param config table
---   @field label string the label for the menu item
---   @field title string the title displayed above the listing
---   @field labelUsedStorage string the label to indicate used storage
---   @field emptyStorage string the text to display if the storage is empty
--- @return PlayerSpaceship
Player.withStorageDisplay = function(self, player, config)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if not Player:hasStorage(player) then error("Player should have a storage", 2) end
    if not Player:hasMenu(player) then error("Expected player " .. player:getCallSign() .. " to have menus enabled, but it does not", 2) end
    if Player:hasStorageDisplay(player) then error("Player already has a storage display", 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    if not isString(config.label) then error("Expected label to be a string, but got " .. typeInspect(config.label), 2) end
    if not isString(config.title) then error("Expected title to be a string, but got " .. typeInspect(config.title), 2) end
    if not isString(config.labelUsedStorage) then error("Expected labelUsedStorage to be a string, but got " .. typeInspect(config.labelUsedStorage), 2) end
    if not isString(config.emptyStorage) then error("Expected emptyStorage to be a string, but got " .. typeInspect(config.emptyStorage), 2) end

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

    return player
end

--- check if the player has a storage display
--- @param self
--- @param player PlayerSpaceship
--- @return boolean
Player.hasStorageDisplay = function(self, player)
    return isTable(player) and player.storageDisplayActive == true
end