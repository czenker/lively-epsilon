Menu = Menu or {}

Menu.newItem = function(self, label, onClick)
    if not isString(label) then error("Expected label to be a string, but got " .. type(label), 2) end
    if not isNil(onClick) and not isFunction(onClick) then error("Expected onClick to be nil or a function, but got " .. type(onClick), 2) end

    return {
        getLabel = function()
            return label
        end,
        onClick = onClick,
    }
end

Menu.isMenuItem = function(self, thing)
    return isTable(thing) and
        isFunction(thing.getLabel) and
        (isNil(thing.onClick) or isFunction(thing.onClick))
end
