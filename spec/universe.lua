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
        getScenarioVariation = _G.getScenarioVariation,
        getObjectsInRadius = _G.getObjectsInRadius,
        getPlayerShip = _G.getPlayerShip,
        addGMFunction = _G.addGMFunction,
        removeGMFunction = _G.removeGMFunction,
        FactionInfo = _G.FactionInfo,
    }
    local nextFactionId = 1
    local factions = {}
    -- two dimensional array with true=enemies, false=friendly
    local factionRelations = {}

    local function setFactionRelation(id1, id2, relation)
        local min = math.min(id1, id2)
        local max = math.max(id1, id2)
        if min == max then return end

        factionRelations[min] = factionRelations[min] or {}
        factionRelations[min][max] = relation
    end
    local function getFactionRelation(id1, id2)
        local min = math.min(id1, id2)
        local max = math.max(id1, id2)
        if min == max then return false end
        -- if no faction was explicitly set, they are neutral
        if min == 0 or max == 0 then return nil end

        factionRelations[min] = factionRelations[min] or {}
        return factionRelations[min][max]
    end

    _G.FactionInfo = function()
        local id = nextFactionId
        nextFactionId = nextFactionId + 1

        local isValid = true
        local theName

        local faction = {
            typeName = "FactionInfo",
            isValid = function() return isValid end,
            destroy = function(self)
                isValid = false
                return self
            end,
            setName = function(self, name)
                theName = name
                return self
            end,
            getId = function(self) return id end,
            getName = function(self) return theName end,
            setGMColor = function(self) return self end,
            setDescription = function(self) return self end,
            setEnemy = function(self, other)
                setFactionRelation(self:getId(), other:getId(), true)
                return self
            end,
            setFriendly = function(self, other)
                setFactionRelation(self:getId(), other:getId(), false)
                return self
            end,
        }
        factions[id] = faction

        return faction
    end


    local getFaction = function(nameOrId)
        if factions[nameOrId] ~= nil then return factions[nameOrId] end

        for _,faction in pairs(factions) do
            if faction:getName() == nameOrId then return faction end
        end
        error("Faction with name or id " .. nameOrId .. " was not defined.", 2)
    end

    local isEnemy = function(self, other)
        return getFactionRelation(self:getFactionId(), other:getFactionId()) == true
    end
    local isFriendly = function(self, other)
        return getFactionRelation(self:getFactionId(), other:getFactionId()) == true
    end

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
            if isFunction(obj.setFaction) and isFunction(obj.setFactionId) and isFunction(obj.isFriendly) and isFunction(obj.isEnemy) then
                local origSetFaction = obj.setFaction
                local origSetFactionId = obj.setFactionId

                obj.setFaction = function(self, faction_name)
                    local faction = getFaction(faction_name)
                    origSetFaction(self, faction:getName())
                    origSetFactionId(self, faction:getId())

                    return self
                end
                obj.setFactionId = function(self, id)
                    if id == 0 then
                        origSetFaction(self, "Independant")
                        origSetFactionId(self, 0)
                    else
                        local faction = getFaction(id)
                        origSetFaction(self, faction:getName())
                        origSetFactionId(self, faction:getId())
                    end

                    return self
                end
                obj.isEnemy = isEnemy
                obj.isFriendly = isFriendly
            end

            return obj
        end
    end

    _G.getPlayerShip = function(id)
        local players = knownObjectsByType["PlayerSpaceship"] or {}
        if id == -1 then return players[1] else return players[id] end
    end

    _G.addGMFunction = function() end
    _G.removeGMFunction = function() end
    _G.getScenarioVariation = function() end

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