Person = {
    byName = function(name)
        return {
            getFormalName = function() return name end,
            getNickName = function() return name end,
        }
    end,

    isPerson = function(thing)
        return isTable(thing) and
                isFunction(thing.getFormalName) and
                isFunction(thing.getNickName)
    end,
}
