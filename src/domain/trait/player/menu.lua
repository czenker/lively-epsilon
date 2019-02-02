Player = Player or {}

local function upperFirst(string)
    return string:sub(1,1):upper() .. string:sub(2)
end

local positions = {"helms", "relay", "science", "weapons", "engineering"}

--- Add menus to the player stations
--- @param self
--- @param player PlayerSpaceship
--- @param config table
---   @field backLabel string label to go back to the main menu
---   @field labelNext string label to go to the next page
---   @field labelPrevious string label to go to the previous page
---   @field itemsPerPage number|table[string,number] how many items to display at most per page
--- @return PlayerSpaceship
Player.withMenu = function(self, player, config)
    config = config or {}
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if Player:hasMenu(player) then error("Player already has menus", 2) end
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    config.backLabel = config.backLabel or "|<<"
    if not isString(config.backLabel) then error("Expected backLabel to be a string, but got " .. typeInspect(config.backLabel), 2) end
    config.labelNext = config.labelNext or "=>"
    if not isString(config.labelNext) then error("Expected labelNext to be a string, but got " .. typeInspect(config.labelNext), 2) end
    config.labelPrevious = config.labelPrevious or "<="
    if not isString(config.labelPrevious) then error("Expected labelPrevious to be a string, but got " .. typeInspect(config.labelPrevious), 2) end
    config.itemsPerPage = config.itemsPerPage or 12
    if isNumber(config.itemsPerPage) then
        local itemsPerPosition = {}
        for _, position in pairs(positions) do
            itemsPerPosition[position] = config.itemsPerPage
        end
        config.itemsPerPage = itemsPerPosition
    end
    if not isTable(config.itemsPerPage) then error("Expected itemsPerPage to be a table, but got " .. typeInspect(config.itemsPerPage), 2) end
    for _,position in pairs(positions) do
        if config.itemsPerPage[position] == nil then error("Expected itemsPerPage to be set for " .. position, 3) end
        if not isNumber(config.itemsPerPage[position]) then error("Expected itemsPerPage to be a positive number for " .. position .. ", but got " .. typeInspect(config.itemsPerPage[position]), 3) end
        if config.itemsPerPage[position] < 4 then error("Expected itemsPerPage for " .. position .. " to be larger than 4, but got " .. config.itemsPerPage[position], 3) end
        if config.itemsPerPage[position] > 16 then logWarning("Setting itemsPerPage higher than 16 can lead to cases where players can not see the back button. Got: " .. config.itemsPerPage) end
    end

    for _,position in pairs(positions) do
        local upper = upperFirst(position)
        local adderName = "add" .. upper .. "MenuItem"
        local removerName = "remove" .. upper .. "MenuItem"
        local drawName = "draw" .. upper .. "Menu"

        local menu = Menu:new()
        local isOnMainMenu = true

        -- EE has problems when removing and adding buttons with the same name in quick succession.
        -- adding a suffix ensures that the name changes.
        local nextSuffix = 0
        local uniqueId = function(id)
            return position .. "_" .. id .. "_" .. nextSuffix
        end

        local currentlyDrawnIds = {}
        local draw
        draw = function(theMenu, page)
            nextSuffix = (nextSuffix + 1) % 10
            if isNumber(theMenu) then
                page = theMenu
                theMenu = nil
            end
            theMenu = theMenu or menu
            local isMainMenu = theMenu == menu

            page = page or 1
            page = math.max(1, page)

            -- sort the items, because items is an unordered table at this point
            local items = theMenu:getItems()
            local ids = {}
            for id,_ in pairs(items) do
                table.insert(ids, id)
            end
            table.sort(ids, function(idA, idB)
                if items[idA]:getPriority() == items[idB]:getPriority() then
                    return idA < idB
                else
                    return items[idA]:getPriority() < items[idB]:getPriority()
                end
            end)

            -- paginate
            local itemsPerPage = config.itemsPerPage[position]
            if not isMainMenu then itemsPerPage = itemsPerPage - 1 end -- compensate for the back button
            local numberOfItems = Util.size(items)
            local firstItemId, lastItemId = 1, 99
            local hasNextButton, hasPreviousButton = false, false

            if page == 1 then
                hasPreviousButton = false
                firstItemId = 1
                lastItemId = firstItemId + itemsPerPage - 1
            else
                hasPreviousButton = true
                firstItemId = itemsPerPage + (page - 2) * (itemsPerPage - 2)
                lastItemId = firstItemId + itemsPerPage - 2 -- one less to compensate for the previous button
            end

            if lastItemId >= numberOfItems then
                -- if the last page
                hasNextButton = false
                lastItemId = math.min(lastItemId, numberOfItems)
            else
                -- if not the last page
                hasNextButton = true
                lastItemId = lastItemId - 1 -- make space for the next button
            end

            isOnMainMenu = isMainMenu

            -- remove the old buttons
            for _, id in pairs(currentlyDrawnIds) do
                player:removeCustom(id)
                currentlyDrawnIds[id] = nil
            end

            -- draw
            for i=firstItemId, lastItemId do
                local id = ids[i]
                local item = items[id]
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
                            logError("Expected onClick to return nil, a string or a menu for menuItem " .. id .. ", but got " .. typeInspect(err))
                        end
                    end)
                else
                    player:addCustomInfo(position, uid, item:getLabel())
                end
            end

            if hasPreviousButton then
                local prevUid = uniqueId("the_magic_previous_button")
                currentlyDrawnIds[prevUid] = prevUid

                player:addCustomButton(position, prevUid, config.labelPrevious, function()
                    -- some reference to the global scope needed to avoid the "upvalue error" in EE
                    -- ??[convert<ScriptSimpleCallback>::param] Upvalue 1 of function is not a table
                    string.format("")
                    draw(theMenu, page - 1)
                end)
            end

            if hasNextButton then
                local nextUid = uniqueId("the_magic_next_button")
                currentlyDrawnIds[nextUid] = nextUid

                player:addCustomButton(position, nextUid, config.labelNext, function()
                    -- some reference to the global scope needed to avoid the "upvalue error" in EE
                    -- ??[convert<ScriptSimpleCallback>::param] Upvalue 1 of function is not a table
                    string.format("")
                    draw(theMenu, page + 1)
                end)
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

        --- draw menu for station
        --- @param self
        --- @param menu Menu (optional) If not given draws the main menu
        --- @return PlayerSpaceship
        player[drawName] = function(self, menu)
            draw(menu)
            return self
        end

        --- add a menu entry to the main menu
        --- @param self
        --- @param id string
        --- @param menuItem MenuItem
        --- @return PlayerSpaceship
        player[adderName] = function(self, id, menuItem)
            menu:addItem(id, menuItem)
            if isOnMainMenu == true then draw() end
            return self
        end

        --- remove a menu entry from the main menu
        --- @param self
        --- @param id string
        --- @return PlayerSpaceship
        player[removerName] = function(self, id)
            menu:removeItem(id)
            if isOnMainMenu == true then draw() end
            return self
        end
    end

    --- add a menu entry to the main menu for that station
    --- @param self
    --- @param position string
    --- @param id string
    --- @param menuItem MenuItem
    --- @return PlayerSpaceship
    player.addMenuItem = function(self, position, id, menuItem)
        if not isString(position) then error("Expected position to be string, but got " .. typeInspect(position), 2) end
        local adderName = "add" .. upperFirst(position) .. "MenuItem"
        if not isFunction(self[adderName]) then error("Invalid position " .. position, 2) end

        self[adderName](self, id, menuItem)
        return self
    end

    --- remove a menu entry from the main menu for that station
    --- @param self
    --- @param position string
    --- @param id string
    --- @return PlayerSpaceship
    player.removeMenuItem = function(self, position, id)
        if not isString(position) then error("Expected position to be string, but got " .. typeInspect(position), 2) end
        local removerName = "remove" .. upperFirst(position) .. "MenuItem"
        if not isFunction(self[removerName]) then error("Invalid position " .. position, 2) end

        self[removerName](self, id)
        return self
    end

    --- draw a menu for a station
    --- @param self
    --- @param position string
    --- @param menu Menu (optional) the menu to draw. If not given draws the main menu
    --- @return PlayerSpaceship
    player.drawMenu = function(self, position, menu)
        if not isString(position) then error("Expected position to be string, but got " .. typeInspect(position), 2) end
        local drawName = "draw" .. upperFirst(position) .. "Menu"
        if not isFunction(self[drawName]) then error("Invalid position " .. position, 2) end

        self[drawName](self, menu)
        return self
    end

    return player
end

--- check if the thing has a menu
--- @param self
--- @param player any
--- @return boolean
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

