ShipTemplateBased = ShipTemplateBased or {}

-- allows to tag the object
ShipTemplateBased.withTags = function (self, spaceObject, ...)
    if not isEeShipTemplateBased(spaceObject) then
        error ("Expected a shipTemplateBased object but got " .. type(spaceObject), 2)
    end
    arg = arg or {}

    local tags = {}

    spaceObject.getTags = function(self)
        local ret = {}
        for k, _ in pairs(tags) do
            table.insert(ret, k)
        end
        return ret
    end
    spaceObject.hasTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. type(tag), 2) end
        return tags[tag] ~= nil
    end
    spaceObject.addTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. type(tag), 2) end
        tags[tag] = true
    end
    spaceObject.addTags = function(self, ...)
        for _,tag in ipairs(arg) do
            self:addTag(tag)
        end
    end
    spaceObject.removeTag = function(self, tag)
        if not isString(tag) then error("a tag needs to be a string, but got " .. type(tag), 2) end
        tags[tag] = nil
    end
    spaceObject.removeTags = function(self, ...)
        for _,tag in ipairs(arg) do
            self:removeTag(tag)
        end
    end

    for _,tag in ipairs(arg) do
        spaceObject:addTag(tag)
    end

end

--- checks if the given object has tags configured
ShipTemplateBased.hasTags = function(self, thing)
    return isFunction(thing.getTags) and
        isFunction(thing.hasTag) and
        isFunction(thing.addTag) and
        isFunction(thing.addTags) and
        isFunction(thing.removeTag) and
        isFunction(thing.removeTags)
end