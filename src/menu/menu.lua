Menu = Menu or {}

Menu.new = function(self)
    local items = {}

    return {
        addItem = function(self, id, menuItem)
            if isNil(menuItem) then
                menuItem = id
                id = Util.randomUuid()
            end
            if not isString(id) then error("Expected id to be a string, but got " .. typeInspect(id), 2) end
            if not Menu:isMenuItem(menuItem) then error("Expected menuItem to be a MenuItem, but got " .. typeInspect(menuItem), 2) end

            items[id] = menuItem
        end,
        removeItem = function(self, id)
            if not isString(id) then error("Expected id to be a string, but got " .. typeInspect(id), 2) end
            items[id] = nil
        end,
        getItems = function()
            local copy = {}
            for id, item in pairs(items) do
                copy[id] = item
            end
            return copy
        end,
    }
end

Menu.isMenu = function(self, thing)
    return isTable(thing) and
        isFunction(thing.addItem) and
        isFunction(thing.removeItem) and
        isFunction(thing.getItems)
end