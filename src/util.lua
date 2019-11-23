Util = {
    --- returns the size of any given table
    --- @param table table
    --- @return number
    size = function(table)
        if not isTable(table) then error("Expected parameter a table, but got " .. typeInspect(table), 2) end
        local cnt = 0
        for _, _ in pairs(table) do
            cnt = cnt + 1
        end

        return cnt
    end,

    --- returns true if the table only contains numberical keys
    --- @param table table
    --- @return boolean
    isNumericTable = function(table)
        return isTable(table) and #table == Util.size(table)
    end,

    --- selects a random item from a table
    --- @param table table
    --- @param filterFunc function an optional filter function for items to consider
    --- @return any|nil
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
            local maxIndex = Util.size(keys)
            if maxIndex < 1 then return nil end
            local index = keys[math.random(1, maxIndex)]
            return table[index]
        else
            return nil
        end
    end,

    --- returns the keys of a table in an arbitrary order
    --- @param input table
    --- @return table
    keys = function(input)
        if not isTable(input) then error("expected table, but got " .. typeInspect(input), 2) end
        local keys = {}
        for k, _ in pairs(input) do
            table.insert(keys, k)
        end
        return keys
    end,

    --- generate a random unique id
    --- @return string
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

    --- randomly sort a table and return a copy
    --- @param input table
    --- @return table
    randomSort = function(input)
        if not isTable(input) then error("Expected a table, but got " .. typeInspect(input), 2) end
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

    --- merges multiple tables together where later tables take precedence
    --- @param ... table
    --- @return table
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

    --- merges multiple tables together where all items of following tables are appended to the first one
    --- @param ... table
    --- @return table
    appendTables = function(...)
        local args = {...}
        local ret = {}
        for i=1,#args do
            for _,v in ipairs(args[i]) do
                table.insert(ret, v)
            end
        end
        return ret
    end,

    --- calculates a vector the given direction and length
    --- @param angle number
    --- @param length number
    --- @return number,number
    vectorFromAngle = function(angle, length)
        return math.cos(angle / 180 * math.pi) * length, math.sin(angle / 180 * math.pi) * length
    end,

    --- add a vector with the given direction an length to the point
    --- @param x number
    --- @param y number
    --- @param angle number
    --- @param length number
    --- @return number,number
    addVector = function(x, y, angle, length)
        if isEeObject(x) then
            length = angle
            angle = y
            x, y = x:getPosition()
        end
        local dx, dy = Util.vectorFromAngle(angle, length)

        return x + dx, y + dy
    end,

    --- calculates the angle of a given vector
    --- @param dx number
    --- @param dy number
    --- @return number
    angleFromVector = function(dx, dy)
        return math.deg(math.atan(dy, dx)), math.sqrt(dx * dx + dy * dy)
    end,

    --- calculate the minimum distance of a point to a line segment
    ---
    --- You can either give two arguments for x and y coordinates or one for a SpaceObject
    ---
    --- @param startX number|SpaceObject x-coordinate of line start
    --- @param startY number|SpaceObject y-coordinate of line start
    --- @param endX number|SpaceObject x-coordinate of line end
    --- @param endY number|SpaceObject|nil y-coordinate of line end
    --- @param x number|SpaceObject|nil x-coordinate of point
    --- @param y number|nil y-coordinate of point
    --- @return number
    distanceToLineSegment = function(startX, startY, endX, endY, x, y)
        if isEeObject(startX) then
            endX, endY, x, y = startY, endX, endY, x
            startX, startY = startX:getPosition()
        end
        if isEeObject(endX) then
            x, y = endY, x
            endX, endY = endX:getPosition()
        end
        if isEeObject(x) then
            x, y = x:getPosition()
        end
        if not isNumber(startX) then error("All arguments have to be numbers, but got " .. typeInspect(startX) .. " as first argument.", 2) end
        if not isNumber(startY) then error("All arguments have to be numbers, but got " .. typeInspect(startY) .. " as second argument.", 2) end
        if not isNumber(endX) then error("All arguments have to be numbers, but got " .. typeInspect(endX) .. " as third argument.", 2) end
        if not isNumber(endY) then error("All arguments have to be numbers, but got " .. typeInspect(endY) .. " as fourth argument.", 2) end
        if not isNumber(x) then error("All arguments have to be numbers, but got " .. typeInspect(x) .. " as fifth argument.", 2) end
        if not isNumber(y) then error("All arguments have to be numbers, but got " .. typeInspect(y) .. " as sixth argument.", 2) end
        if startX == endX and startY == endY then error(string.format("start and end should not be the same point, but got (%f, %f).", startX, startY), 2) end

        local xd = endX - startX
        local yd = endY - startY

        local d = (xd * (x - startX) + yd * (y - startY)) / (xd*xd + yd*yd)

        if d < 0 then
            return distance(startX, startY, x, y)
        elseif d > 1 then
            return distance(endX, endY, x, y)
        else
            -- this is the closest location to the point on the line segment
            local px = d * xd + startX
            local py = d * yd + startY

            return distance(x, y, px, py)
        end
    end,

    --- returns the heading in the coordinate system used for the science station
    --- @param a SpaceShip|integer
    --- @param b SpaceShip|integer
    --- @param c SpaceShip|integer|nil
    --- @param d integer|nil
    --- @return number
    heading = function(a, b, c, d)
        local x1, y1 = 0, 0
        local x2, y2 = 0, 0
        if isEeObject(a) and isEeObject(b) then
            x1, y1 = a:getPosition()
            x2, y2 = b:getPosition()
        elseif isEeObject(a) and isNumber(b) and isNumber(c) then
            x1, y1 = a:getPosition()
            x2, y2 = b, c
        elseif isNumber(a) and isNumber(b) and isEeObject(c) then
            x1, y1 = a, b
            x2, y2 = c:getPosition()
        elseif isNumber(a) and isNumber(b) and isNumber(c) and isNumber(d) then
            x1, y1 = a, b
            x2, y2 = c, d
        else
            error(string.format("heading() function used incorrectly. Expected coordinates or two Space objects, but got %s, %s, %s, %s.", typeInspect(a), typeInspect(b), typeInspect(c), typeInspect(d)) , 2)
        end

        return (Util.angleFromVector(x2 - x1, y2 - y1) + 90) % 360
    end,

    --- calculates the difference between to angles - which ever direction is shorter
    --- @param angle1 number
    --- @param angle2 number
    --- @return number a number between 0 and 180
    angleDiff = function(angle1, angle2)
        local diff = (angle2 - angle1) % 360
        if math.abs(diff) > 180 then
            return diff - 360
        else
            return diff
        end
    end,

    --- spawns a ship at the station
    --- @param station SpaceStation
    --- @param obj SpaceShip
    --- @param distance number default: 500
    spawnAtStation = function(station, obj, distance)
        distance = distance or 500
        local x, y = station:getPosition()
        local angle = math.random(0, 360)
        local dx, dy = Util.vectorFromAngle(angle, distance)
        return obj:setPosition(x + dx, y + dy):setRotation(angle)
    end,

    --- selects a point on a vector
    --- @param x1 number
    --- @param y1 number
    --- @param x2 number
    --- @param y2 number
    --- @param ratio number if ratio is `0` it will return `x1,y1`, if ratio is `1` it will return `x2,y2`
    --- @return number,number
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

    --- returns a copy of a table
    --- @see http://lua-users.org/wiki/CopyTable
    --- @param orig table
    --- @return table
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

    --- map all values of a table by a mapping function
    --- @param table table
    --- @param mappingFunc function the faction gets an entry from the table. Should return the new value.
    --- @return table
    map = function(table, mappingFunc)
        if not isTable(table) then error("expected first argument to be a table, but got " .. typeInspect(table), 2) end
        if not isFunction(mappingFunc) then error("expected second argument to be a function, but got " .. typeInspect(mappingFunc), 2) end

        local ret = {}
        for k,v in pairs(table) do
            ret[k] = mappingFunc(v, k)
        end

        return ret
    end,

    --- create a string from a table by concatenating
    --- @param table table[string]
    --- @param separator string
    --- @param lastSeparator string the seperator between the last and the second to last item are seperated
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

    --- rounds mathematically correct
    --- @param number number
    --- @param base number (default: `1`) if given it rounds to the closest multiple of `base`
    --- @return number
    round = function(number, base)
        if base == nil or base == 1 then
            return math.floor(number + 0.5)
        else
            return math.floor((number + base/2) / base) * base
        end
    end,

    --- calculates the total damage the Lasers can deal per second
    --- @deprecated
    --- @param ship SpaceShip
    --- @return number
    totalLaserDps = function(ship)
        if not isEeShip(ship) and not isEePlayer(ship) then error("Expected ship to be a Ship or player, but got " .. typeInspect(ship), 2) end
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

    --- calculates the total current shield level of a ship
    --- @deprecated
    --- @param ship SpaceShip
    --- @return number
    totalShieldLevel = function(ship)
        if not isEeShipTemplateBased(ship) then error("Expected ship to be a ShipTemplateBased, but got " .. typeInspect(ship), 2) end
        local total = 0
        for i=0,ship:getShieldCount()-1 do
            total = total + ship:getShieldLevel(i)
        end

        return total
    end,

    --- gets the sector name by coordinates
    --- @param x number
    --- @param y number
    --- @return string
    sectorName = function(x, y)
        local a = Artifact():setPosition(x, y)
        local sectorName = a:getSectorName()
        a:destroy()
        return sectorName
    end,
}