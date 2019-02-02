Menu = Menu or {}

--- create a new menu item
--- @param self
--- @param label string the human readable label of this menu entry
--- @param onClick string|nil|MenuObject|function defines what happens when the menu item is clicked. `nil` is a non-clickable label, a `string` will be shown in a pop-up, `MenuObject` opens this menu as submenu, and `function` can return a `string` or `Menu`
--- @param priority number (default: `0`)
--- @return MenuItemObject
Menu.newItem = function(self, label, onClick, priority)
    if not isString(label) then error("Expected label to be a string, but got " .. typeInspect(label), 2) end
    if isNumber(onClick) then
        priority = onClick
        onClick = nil
    end
    if isString(onClick) or Menu:isMenu(onClick) then
        local backupOnClick = onClick
        onClick = function() return backupOnClick end
    end
    if not isNil(onClick) and not isFunction(onClick) then error("Expected onClick to be nil or a function, but got " .. typeInspect(onClick), 2) end
    priority = priority or 0
    if not isNumber(priority) then error("Expected priority to be a number, but got " .. typeInspect(priority), 2) end

    return {
        --- get the label of the menu item
        --- @internal
        --- @param self
        --- @return string
        getLabel = function(self)
            return label
        end,
        --- what happens when the button is clicked
        --- @internal
        --- @return nil|function
        onClick = onClick,
        --- get the priority for this item in the menu list
        --- @internal
        --- @param self
        --- @return number
        getPriority = function(self)
            return priority
        end
    }
end

--- checks if a given thing is a valid MenuItem
--- @param self
--- @param thing any
--- @return boolean
Menu.isMenuItem = function(self, thing)
    return isTable(thing) and
        isFunction(thing.getLabel) and
        isFunction(thing.getPriority) and
        (isNil(thing.onClick) or isFunction(thing.onClick))
end
