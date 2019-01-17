Generic = Generic or {}

-- allows to tag the object
Generic.withTags = function (self, thing, ...)
    if not isTable(thing) then
        error ("Expected an object but got " .. typeInspect(thing), 2)
    end

    local tags = {}

    thing.getTags = function(self)
        local ret = {}
        for k, _ in pairs(tags) do
            table.insert(ret, k)
        end
        return ret
    end
    thing.hasTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. typeInspect(tag), 2) end
        return tags[tag] ~= nil
    end
    thing.addTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. typeInspect(tag), 2) end
        tags[tag] = true
    end
    thing.addTags = function(self, ...)
        for _,tag in ipairs({...}) do
            self:addTag(tag)
        end
    end
    thing.removeTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. typeInspect(tag), 2) end
        tags[tag] = nil
    end
    thing.removeTags = function(self, ...)
        for _,tag in ipairs({...}) do
            self:removeTag(tag)
        end
    end


    for _,tag in ipairs({...}) do
        thing:addTag(tag)
    end

end

--- checks if the given object has tags configured
Generic.hasTags = function(self, thing)
    return isFunction(thing.getTags) and
        isFunction(thing.hasTag) and
        isFunction(thing.addTag) and
        isFunction(thing.addTags) and
        isFunction(thing.removeTag) and
        isFunction(thing.removeTags)
end