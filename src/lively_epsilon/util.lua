Util = {
    size = function(array)
        local cnt = 0
        for _, _ in pairs( array ) do
            cnt = cnt + 1
        end

        return cnt
    end,

    isNumericTable = function(table)
        return isTable(table) and #table == Util.size(table)
    end,

    random = function(table, filterFunc)
        if type(table) == "table" and Util.size(table) > 0 then
            local keys = {}
            for key, value in pairs(table) do
                local selectItem
                if isFunction(filterFunc) then
                    selectItem = filterFunc(key, value)
                else
                    selectItem = true
                end
                if selectItem == true then
                    keys[#keys+1] = key --Store keys in another table
                end
            end
            local index = keys[math.random(1, Util.size(keys))]
            return table[index]
        else
            return nil
        end
    end,

    randomUuid = function()
        local string = ""
        for i=1,16,1 do
            local val = math.random(0,15)
            if val >= 0 and val <= 9 then
                string = string .. val
            elseif val == 10 then
                string = string .. "a"
            elseif val == 11 then
                string = string .. "b"
            elseif val == 12 then
                string = string .. "c"
            elseif val == 13 then
                string = string .. "d"
            elseif val == 14 then
                string = string .. "e"
            elseif val == 15 then
                string = string .. "f"
            end
        end

        return string
    end,

    randomSort = function(input)
        if not isTable(input) then error("Expected a table, but got " .. type(input), 2) end
        local copy = {}
        local idx = 1
        for _, v in pairs(input) do
            copy[idx] = v
            idx = idx + 1
        end
        local length = Util.size(copy)
        for i = length, 2, -1 do
            local j = math.random(1, i)
            copy[i], copy[j] = copy[j], copy[i]
        end
        return copy
    end,

    -- merges multiple tables together where later tables take precedence
    mergeTables = function(...)
        local args = {...}
        local ret = {}
        for i=1,#args do
            for k,v in pairs(args[i]) do
                ret[k] = v
            end
        end
        return ret
    end,

    vectorFromAngle = function(angle, length)
        return math.cos(angle / 180 * math.pi) * length, math.sin(angle / 180 * math.pi) * length
    end,

    spawnAtStation = function(station, obj)
        local x, y = station:getPosition()
        local angle = math.random(0, 360)
        local dx, dy = Util.vectorFromAngle(angle, 500)
        return obj:setPosition(x + dx, y + dy):setRotation(angle)
    end,

    onVector = function(x1, y1, x2, y2, ratio)
        if isEeShipTemplateBased(x1) then
            if isEeShipTemplateBased(y1) then
                ratio = x2
                x2, y2 = y1:getPosition()
                x1, y1 = x1:getPosition()
            else
                ratio = y2
                y2 = x2
                x2 = y1
                x1, y1 = x1:getPosition()
            end
        elseif isEeShipTemplateBased(x2) then
            ratio = y2
            x2, y2 = x2:getPosition()
        end
        return x1 + (x2 - x1) * ratio, y1 + (y2 - y1) * ratio
    end,

    --- copies a thing (table) recursive
    -- @ see http://lua-users.org/wiki/CopyTable
    deepCopy = function (orig)
        local copy
        if isTable(orig) and not isEeObject(orig) then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[Util.deepCopy(orig_key)] = Util.deepCopy(orig_value)
            end
            setmetatable(copy, Util.deepCopy(getmetatable(orig)))
        else -- number, string, boolean, etc
          copy = orig
        end
        return copy
    end,

    map = function(table, mappingFunc)
        if not isTable(table) then error("expected first argument to be a table, but got " .. type(table), 2) end
        if not isFunction(mappingFunc) then error("expected second argument to be a function, but got " .. type(mappingFunc), 2) end

        local ret = {}
        for k,v in pairs(table) do
            ret[k] = mappingFunc(v)
        end

        return ret
    end,

    mkString = function(table, separator, lastSeparator)
        if not Util.isNumericTable(table) then
            error("The given table needs to have numerical indices.", 2)
        end

        local string = ""

        local lastIndex = 0
        for k, _ in pairs(table) do
            lastIndex = k
        end

        local isFirst = true
        for k, value in pairs(table) do
            if isFirst then
                string = string .. value
                isFirst = false
            else
                if k == lastIndex and lastSeparator ~= nil then
                    -- if last element
                    string = string .. lastSeparator .. value
                else
                    string = string .. separator .. value
                end
            end
        end

        return string
    end,

    totalLaserDps = function(ship)
        if not isEeShip(ship) and not isEePlayer(ship) then error("Expected ship to be a Ship or player, but got " .. type(ship), 2) end
        local total = 0
        for i=1,16 do
            local cycleTime = ship:getBeamWeaponCycleTime(i)
            local damage = ship:getBeamWeaponDamage(i)
            if cycleTime > 0 then
                total = total + damage / cycleTime
            end
        end

        return total
    end,

    totalShieldLevel = function(ship)
        if not isEeShipTemplateBased(ship) then error("Expected ship to be a ShipTemplateBased, but got " .. type(ship), 2) end
        local total = 0
        for i=1,ship:getShieldCount() do
            total = total + ship:getShieldLevel(i)
        end

        return total
    end,

    sectorName = function(x, y)
        local a = Artifact():setPosition(x, y)
        local sectorName = a:getSectorName()
        a:destroy()
        return sectorName
    end,
}