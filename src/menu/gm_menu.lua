Menu = Menu or {}

local menu = Menu:new()
local currentlyDrawnIds = {}
local isOnMainMenu = true
local itemsPerPage = 10
local labelBack = "|<<"
local labelPrevious = "<="
local labelNext = "=>"

local draw
draw = function(theMenu, page)
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
    local itemsPerPage = itemsPerPage
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
        removeGMFunction(id)
        currentlyDrawnIds[id] = nil
    end

    -- draw
    for i=firstItemId, lastItemId do
        local id = ids[i]
        local item = items[id]
        local label = item:getLabel()
        currentlyDrawnIds[label] = label
        if isFunction(item.onClick) then
            addGMFunction(label, function()
                local status, err = pcall(item.onClick)
                if not status then
                    local errorMsg = "An error occurred while calling onClick of gm menuItem " .. label
                    if isString(err) then
                        errorMsg = errorMsg .. ": " .. err
                    end
                    logError(errorMsg)
                elseif Menu:isMenu(err) then
                    draw(err)
                elseif isNil(err) then
                    -- OK: function had side-effects
                else
                    logError("Expected onClick to return nil, or a menu for menuItem \"" .. label .. "\", but got " .. typeInspect(err))
                end
            end)
        else
            logWarning("The GM Menu does not allow MenuItems without onClick function, like " .. item:getLabel())
        end
    end

    if hasPreviousButton then
        currentlyDrawnIds[labelPrevious] = labelPrevious

        addGMFunction(labelPrevious, function()
            -- some reference to the global scope needed to avoid the "upvalue error" in EE
            -- ??[convert<ScriptSimpleCallback>::param] Upvalue 1 of function is not a table
            string.format("")
            draw(theMenu, page - 1)
        end)
    end

    if hasNextButton then
        currentlyDrawnIds[labelNext] = labelNext

        addGMFunction(labelNext, function()
            -- some reference to the global scope needed to avoid the "upvalue error" in EE
            -- ??[convert<ScriptSimpleCallback>::param] Upvalue 1 of function is not a table
            string.format("")
            draw(theMenu, page + 1)
        end)
    end

    if theMenu ~= menu then
        currentlyDrawnIds[labelBack] = labelBack
        addGMFunction(labelBack, function()
            -- some reference to the global scope needed to avoid the "upvalue error" in EE
            -- ??[convert<ScriptSimpleCallback>::param] Upvalue 1 of function is not a table
            string.format("")
            draw()
        end)
    end

end

--- add a menu item to the main menu of the GM screen
--- @param self
--- @param menuItem MenuItem
Menu.addGmMenuItem = function(self, menuItem)
    menu:addItem(menuItem:getLabel(), menuItem)
    if isOnMainMenu == true then draw() end
    return self
end

--- add a menu item to the main menu of the GM screen
--- @param self
--- @param label string the label of the menu item to remove
Menu.removeGmMenuItem = function(self, label)
    menu:removeItem(label)
    if isOnMainMenu == true then draw() end
    return self
end

--- draw a specific menu on the GM screen
--- @param self
--- @param menu Menu (optional) the menu to draw. Draws the main menu by default.
Menu.drawGmMenu = function(self, menu)
    draw(menu)
    return self
end