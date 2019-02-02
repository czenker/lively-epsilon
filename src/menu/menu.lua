Menu = Menu or {}

--- create a new menu entry
--- @param self
--- @return MenuObject
Menu.new = function(self)
    local items = {}

    return {
        --- add an entry to the menu
        --- @param self
        --- @param id string (optional) the unique identifier for this entry
        --- @param menuItem MenuItemObject
        addItem = function(self, id, menuItem)
            if isNil(menuItem) then
                menuItem = id
                id = Util.randomUuid()
            end
            if not isString(id) then error("Expected id to be a string, but got " .. typeInspect(id), 2) end
            if not Menu:isMenuItem(menuItem) then error("Expected menuItem to be a MenuItem, but got " .. typeInspect(menuItem), 2) end

            items[id] = menuItem
        end,
        --- remove an entry from the menu
        --- @param self
        --- @param id string
        removeItem = function(self, id)
            if not isString(id) then error("Expected id to be a string, but got " .. typeInspect(id), 2) end
            items[id] = nil
        end,
        --- get all items from the menu
        --- @return table[MenuItemObject]
        getItems = function()
            local copy = {}
            for id, item in pairs(items) do
                copy[id] = item
            end
            return copy
        end,
    }
end

--- checks if a given thing is a valid Menu
--- @param self
--- @param thing any
--- @return boolean
Menu.isMenu = function(self, thing)
    return isTable(thing) and
        isFunction(thing.addItem) and
        isFunction(thing.removeItem) and
        isFunction(thing.getItems)
end