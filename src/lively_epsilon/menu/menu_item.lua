Menu = Menu or {}

Menu.newItem = function(self, label, onClick, priority)
    if not isString(label) then error("Expected label to be a string, but got " .. type(label), 2) end
    if isNumber(onClick) then
        priority = onClick
        onClick = nil
    end
    if isString(onClick) or Menu:isMenu(onClick) then
        local backupOnClick = onClick
        onClick = function() return backupOnClick end
    end
    if not isNil(onClick) and not isFunction(onClick) then error("Expected onClick to be nil or a function, but got " .. type(onClick), 2) end
    priority = priority or 0
    if not isNumber(priority) then error("Expected priority to be a number, but got " .. type(priority), 2) end

    return {
        getLabel = function()
            return label
        end,
        onClick = onClick,
        getPriority = function()
            return priority
        end
    }
end

Menu.isMenuItem = function(self, thing)
    return isTable(thing) and
        isFunction(thing.getLabel) and
        isFunction(thing.getPriority) and
        (isNil(thing.onClick) or isFunction(thing.onClick))
end
