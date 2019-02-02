Generic = Generic or {}

--- allows to tag any object with strings
--- @param self
--- @param thing table
--- @param ... string the strings to add as tags
--- @return table
Generic.withTags = function (self, thing, ...)
    if not isTable(thing) then
        error ("Expected an object but got " .. typeInspect(thing), 2)
    end

    local tags = {}

    --- get all tags assigned to this object
    --- @param self
    --- @return table[string]
    thing.getTags = function(self)
        local ret = {}
        for k, _ in pairs(tags) do
            table.insert(ret, k)
        end
        return ret
    end
    --- check if the thing has a tag
    --- @param self
    --- @param tag string
    --- @return boolean
    thing.hasTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. typeInspect(tag), 2) end
        return tags[tag] ~= nil
    end
    --- add a tag
    --- @param self
    --- @param tag string
    thing.addTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. typeInspect(tag), 2) end
        tags[tag] = true
    end
    --- add multiple tags
    --- @param self
    --- @param ... string
    thing.addTags = function(self, ...)
        for _,tag in ipairs({...}) do
            self:addTag(tag)
        end
    end
    --- remove a tag
    --- @param self
    --- @param tag string
    thing.removeTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. typeInspect(tag), 2) end
        tags[tag] = nil
    end
    --- remove multiple tags
    --- @param self
    --- @param ... string
    thing.removeTags = function(self, ...)
        for _,tag in ipairs({...}) do
            self:removeTag(tag)
        end
    end


    for _,tag in ipairs({...}) do
        thing:addTag(tag)
    end

    return thing
end

--- checks if the given object has tags configured
--- @param self
--- @param thing any
--- @return booelan
Generic.hasTags = function(self, thing)
    return isFunction(thing.getTags) and
        isFunction(thing.hasTag) and
        isFunction(thing.addTag) and
        isFunction(thing.addTags) and
        isFunction(thing.removeTag) and
        isFunction(thing.removeTags)
end