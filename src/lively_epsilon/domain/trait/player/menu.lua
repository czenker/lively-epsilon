Player = Player or {}

local function upperFirst(string)
    return string:sub(1,1):upper() .. string:sub(2)
end

-- config
-- - backLabel
Player.withMenu = function(self, player, config)
    config = config or {}
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. type(player), 2) end
    if Player:hasMenu(player) then error("Player already has menus", 2) end
    if not isTable(config) then error("Expected config to be a table, but got " .. type(config), 2) end
    config.backLabel = config.backLabel or "<-"
    if not isString(config.backLabel) then error("Expected backLabel to be a string, but got " .. type(config.backLabel), 2) end

    for _,position in pairs({"helms", "relay", "science", "weapons", "engineering"}) do
        local upper = upperFirst(position)
        local adderName = "add" .. upper .. "MenuItem"
        local removerName = "remove" .. upper .. "MenuItem"
        local drawName = "draw" .. upper .. "Menu"

        local menu = Menu:new()

        -- EE has problems when removing and adding buttons with the same name in quick succession.
        -- adding a suffix ensures that the name changes.
        local nextSuffix = 0
        local uniqueId = function(id)
            return position .. "_" .. id .. "_" .. nextSuffix
        end

        local currentlyDrawnIds = {}
        local draw
        draw = function(theMenu)
            nextSuffix = (nextSuffix + 1) % 10
            theMenu = theMenu or menu

            for _, id in pairs(currentlyDrawnIds) do
                player:removeCustom(id)
                currentlyDrawnIds[id] = nil
            end

            for id,item in pairs(theMenu:getItems()) do
                local uid = uniqueId(id)
                currentlyDrawnIds[uid] = uid
                if isFunction(item.onClick) then
                    player:addCustomButton(position, uid, item:getLabel(), function()
                        local status, err = pcall(item.onClick, player, position)
                        if not status then
                            local errorMsg = "An error occurred while calling onClick of menuItem " .. id
                            if isString(err) then
                                errorMsg = errorMsg .. ": " .. err
                            end
                            logError(errorMsg)
                        elseif isString(err) then
                            player:addCustomMessage(position, uid .. "_popup", err)
                        elseif Menu:isMenu(err) then
                            draw(err)
                        elseif isNil(err) then
                            -- OK: function had side-effects
                        else
                            logError("Expected onClick to return nil, a string or a menu for menuItem " .. id .. ", but got " .. type(err), 2)
                        end
                    end)
                else
                    player:addCustomInfo(position, uid, item:getLabel())
                end
            end

            if theMenu ~= menu then
                local backUid = uniqueId("the_magic_back_button")
                currentlyDrawnIds[backUid] = backUid
                player:addCustomButton(position, backUid, config.backLabel, function()
                    -- some reference to the global scope needed to avoid the "upvalue error" in EE
                    -- ??[convert<ScriptSimpleCallback>::param] Upvalue 1 of function is not a table
                    string.format("")
                    draw()
                end)
            end

        end

        player[drawName] = function(self, menu)
            draw(menu)
            return self
        end
        player[adderName] = function(self, id, menuItem)
            menu:addItem(id, menuItem)
            draw()
            return self
        end
        player[removerName] = function(self, id)
            menu:removeItem(id)
            draw()
            return self
        end
    end

    player.addMenuItem = function(self, position, id, menuItem)
        if not isString(position) then error("Expected position to be string, but got " .. type(position), 2) end
        local adderName = "add" .. upperFirst(position) .. "MenuItem"
        if not isFunction(self[adderName]) then error("Invalid position " .. position, 2) end

        self[adderName](self, id, menuItem)
        return self
    end
    player.removeMenuItem = function(self, position, id)
        if not isString(position) then error("Expected position to be string, but got " .. type(position), 2) end
        local removerName = "remove" .. upperFirst(position) .. "MenuItem"
        if not isFunction(self[removerName]) then error("Invalid position " .. position, 2) end

        self[removerName](self, id)
        return self
    end
    player.drawMenu = function(self, position, menu)
        if not isString(position) then error("Expected position to be string, but got " .. type(position), 2) end
        local drawName = "draw" .. upperFirst(position) .. "Menu"
        if not isFunction(self[drawName]) then error("Invalid position " .. position, 2) end

        self[drawName](self, menu)
        return self
    end
end

Player.hasMenu = function(self, player)
    return isTable(player) and
            isFunction(player.addMenuItem) and
            isFunction(player.addHelmsMenuItem) and
            isFunction(player.addRelayMenuItem) and
            isFunction(player.addScienceMenuItem) and
            isFunction(player.addWeaponsMenuItem) and
            isFunction(player.addEngineeringMenuItem) and
            isFunction(player.removeMenuItem) and
            isFunction(player.removeHelmsMenuItem) and
            isFunction(player.removeRelayMenuItem) and
            isFunction(player.removeScienceMenuItem) and
            isFunction(player.removeWeaponsMenuItem) and
            isFunction(player.removeEngineeringMenuItem) and
            isFunction(player.drawMenu) and
            isFunction(player.drawHelmsMenu) and
            isFunction(player.drawRelayMenu) and
            isFunction(player.drawScienceMenu) and
            isFunction(player.drawWeaponsMenu) and
            isFunction(player.drawEngineeringMenu)
end

