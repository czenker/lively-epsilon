Player = Player or {}

local systems = {"reactor", "beamweapons", "missilesystem", "maneuver", "impulse", "warp", "jumpdrive", "frontshield", "rearshield"}

-- config
-- - slots
-- - label
-- - labelLoad
-- - labelStore
-- - labelLoadItem
-- - labelStoreItem
-- - labelReset
-- - labelInfo
-- - infoText

Player.withPowerPresets = function(self, player, config)
    config = config or {}
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. type(player), 2) end
    if Player:hasPowerPresets(player) then error("Player " .. player:getCallSign() .. " already has power presets enabled", 2) end
    if not Player:hasMenu(player) then error("Expected player " .. player:getCallSign() .. " to have menus enabled, but it does not", 2) end
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    config.slots = config.slots or 8
    if not isNumber(config.slots) or config.slots < 1 then error("Expected slots to be a positive number, but got " .. type(config.slots), 2) end
    if not isString(config.label) then error("Expected label to be a string, but got " .. type(config.label), 2) end
    if not isString(config.labelLoad) then error("Expected labelLoad to be a string, but got " .. type(config.labelLoad), 2) end
    if not isString(config.labelStore) then error("Expected labelStore to be a string, but got " .. type(config.labelStore), 2) end
    if not isString(config.labelLoadItem) then error("Expected labelLoadItem to be a string, but got " .. type(config.labelLoadItem), 2) end
    if not isString(config.labelStoreItem) then error("Expected labelStoreItem to be a string, but got " .. type(config.labelStoreItem), 2) end
    if not isNil(config.labelReset) and not isString(config.labelReset) then error("Expected labelReset to be nil or a string, but got " .. type(config.labelReset), 2) end
    if not isNil(config.labelInfo) and not isString(config.labelInfo) then error("Expected labelInfo to be nil or a string, but got " .. type(config.labelInfo), 2) end
    if not isNil(config.infoText) and not isString(config.infoText) then error("Expected infoText to be a string, but got " .. type(config.infoText), 2) end

    local loadMenu = Menu:new()
    loadMenu:addItem("heading", Menu:newItem(config.labelLoad, 0))

    local storeMenu = Menu:new()
    storeMenu:addItem("heading", Menu:newItem(config.labelStore, 0))
    for i=1,config.slots do
        local power = {}
        local coolant = {}

        loadMenu:addItem("load_" .. i, Menu:newItem(config.labelLoadItem .. " " .. i, function()
            for _,system in pairs(systems) do
                if power[system] ~= nil then player:commandSetSystemPowerRequest(system, power[system]) end
                if coolant[system] ~= nil then player:commandSetSystemCoolantRequest(system, coolant[system]) end
            end
        end, i))
        storeMenu:addItem("store_" .. i, Menu:newItem(config.labelStoreItem .. " " .. i, function()
            for _,system in pairs(systems) do
                power[system] = player:getSystemPower(system)
                coolant[system] = player:getSystemCoolant(system)
            end
        end, i))
    end

    local mainMenu = Menu:new()
    mainMenu:addItem("heading", Menu:newItem(config.label, 0))
    mainMenu:addItem("load", Menu:newItem(config.labelLoad, loadMenu, 1))
    mainMenu:addItem("store", Menu:newItem(config.labelStore, storeMenu, 2))

    if isString(config.labelReset) then
        mainMenu:addItem("reset", Menu:newItem(config.labelReset, function()
            for _,system in pairs(systems) do
                player:commandSetSystemPowerRequest(system, 1)
                player:commandSetSystemCoolantRequest(system, 0)
            end
        end, 3))
    end
    if isString(config.labelInfo) and isString(config.infoText) then
        mainMenu:addItem("info", Menu:newItem(config.labelInfo, config.infoText, 4))
    end

    player:addMenuItem("engineering", "presets", Menu:newItem(config.label, mainMenu))

    player.powerPresetsActive = true
end

Player.hasPowerPresets = function(self, player)
    return isTable(player) and player.powerPresetsActive == true
end

