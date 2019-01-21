local distance = function(x1, y1, x2, y2)
    local xd, yd = (x1 - x2), (y1 - y2)
    return math.sqrt(xd * xd + yd * yd)
end

local getObjectsInRange = function(self, radius)
    local x,y = self:getPosition()
    local things = _G.getObjectsInRadius(x, y, radius)

    -- remove yourself
    local foundKey = nil
    for key,thing in pairs(things) do
        if thing == self then foundKey = key end
    end
    if foundKey ~= nil then table.remove(things, foundKey) end
    return things
end

-- creates a mock universe
function withUniverse(func)
    local universe = {
        knownObjects = {},
        players = {},
        add = function(self, ...)
            for _,thing in pairs({...}) do
                if isFunction(thing.getPosition) then
                    thing.getObjectsInRange = getObjectsInRange
                end
                table.insert(self.knownObjects, thing)
                if isEePlayer(thing) then
                    table.insert(self.players, thing)
                end
            end
        end,
        destroy = function()
            _G.getObjectsInRadius = nil
        end,
    }

    _G.getObjectsInRadius = function(x, y, radius)
        local ret = {}
        for _, thing in pairs(universe.knownObjects) do
            if isFunction(thing.isValid) and thing:isValid() and isFunction(thing.getPosition) then
                local xt, yt = thing:getPosition()
                if distance(xt, yt, x, y) <= radius then
                    table.insert(ret, thing)
                end
            end
        end

        return ret
    end

    _G.getPlayerShip = function(id)
        if id == -1 then return universe.players[1] else return universe.players[id] end
    end

    func(universe)
end