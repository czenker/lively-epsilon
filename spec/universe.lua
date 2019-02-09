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
    local knownObjects = {}
    local knownObjectsByType = {}
    local backup = {
        getObjectsInRadius = _G.getObjectsInRadius,
        getPlayerShip = _G.getPlayerShip,
        addGMFunction = _G.addGMFunction,
        removeGMFunction = _G.removeGMFunction,
    }

    _G.getObjectsInRadius = function(x, y, radius)
        local ret = {}
        for _, thing in pairs(knownObjects) do
            if isFunction(thing.isValid) and thing:isValid() and isFunction(thing.getPosition) then
                local xt, yt = thing:getPosition()
                if distance(xt, yt, x, y) <= radius then
                    table.insert(ret, thing)
                end
            end
        end

        return ret
    end

    for _,thing in pairs({
        --"SpaceObject",
        --"ShipTemplateBasedObject",
        --"SpaceShip",
        "SpaceStation",
        "CpuShip",
        "PlayerSpaceship",
        "Artifact",
        "Asteroid",
        "WarpJammer",
        "ScanProbe",
        "SupplyDrop",
        "WormHole",
        "Planet",
        "Mine",
        "Nebula",
    }) do
        local original = _G[thing]
        if original == nil then error(thing .. " does not exist. Did you include the mocks?", 2) end

        backup[thing] = _G[thing]
        _G[thing] = function()
            local obj = original()
            table.insert(knownObjects, obj)
            knownObjectsByType[obj.typeName] = knownObjectsByType[obj.typeName] or {}
            table.insert(knownObjectsByType[obj.typeName], obj)

            if isFunction(obj.getObjectsInRange) then
                obj.getObjectsInRange = function(self, radius)
                    local x, y = self:getPosition()
                    return getObjectsInRadius(x, y, radius)
                end
            end
            if isFunction(obj.areEnemiesInRange) then
                obj.areEnemiesInRange = function(self, radius)
                    for _, obj in pairs(self:getObjectsInRange(radius)) do
                        if obj:isEnemy(self) then return true end
                    end
                    return false
                end
            end

            return obj
        end
    end

    _G.getPlayerShip = function(id)
        local players = knownObjectsByType["PlayerSpaceship"]
        if id == -1 then return players[1] else return players[id] end
    end

    _G.addGMFunction = function() end
    _G.removeGMFunction = function() end

    local success, err = pcall(func)

    for name, func in pairs(backup) do
        _G[name] = func
    end

    if not success then
        error(err)
    else
        return err
    end
end