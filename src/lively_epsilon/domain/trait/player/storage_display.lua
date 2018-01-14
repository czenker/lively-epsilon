Player = Player or {}

Player.withStorageDisplay = function(self, player)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. type(player), 2) end
    if not Player:hasStorage(player) then error("Player should have a storage", 2) end
    if Player:hasStorageDisplay(player) then error("Player already has a storage display", 2) end

    -- The integration will probably change, because I think having some kind of menu structure might be the better option
    -- And it should be possible to translate or modify this. :)

    local buttonId = "storage_display"
    local buttonLabel = "Storage"
    local crewPosition = "engineering"

    player:addCustomButton(crewPosition, buttonId, buttonLabel, function()
        local products = player:getStoredProducts()
        local text = "Storage used: " .. player:getStorageSpace() .. "/" .. player:getMaxStorageSpace() .. "\n\n"

        if Util.size(products) == 0 then
            text = text .. "Your storage is empty."
        else
            for _,product in pairs(products) do
                text = text .. " * ".. player:getProductStorage(product) .. " x " .. product:getName() .. "\n"
            end
        end

        player:addCustomMessage(crewPosition, buttonLabel, text)
    end)

    player.storageDisplayActive = true

end

Player.hasStorageDisplay = function(self, player)
    return isTable(player) and player.storageDisplayActive
end