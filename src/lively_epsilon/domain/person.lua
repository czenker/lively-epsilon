Person = {
    byName = function(name, nickName)
        return {
            getFormalName = function() return name end,
            getNickName = function() return nickName or name end,
        }
    end,

    isPerson = function(self, thing)
        return isTable(thing) and
                isFunction(thing.getFormalName) and
                isFunction(thing.getNickName)
    end,
}

setmetatable(Person,{
    __index = Generic
})