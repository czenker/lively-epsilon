Person = {
    --- create a new Person by name
    --- @param self
    --- @param name string
    --- @param nickName string|nil
    --- @return Person
    byName = function(self, name, nickName)
        return {
            getFormalName = function() return name end,
            getNickName = function() return nickName or name end,
        }
    end,

    --- check if the given thing is a person
    --- @param self
    --- @param thing any
    --- @return boolean
    isPerson = function(self, thing)
        return isTable(thing) and
                isFunction(thing.getFormalName) and
                isFunction(thing.getNickName)
    end,
}

setmetatable(Person,{
    __index = Generic
})