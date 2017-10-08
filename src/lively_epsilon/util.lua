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

    random = function(table)
        if type(table) == "table" and Util.size(table) > 0 then
            local keys = {}
            for key, _ in pairs(table) do
                keys[#keys+1] = key --Store keys in another table
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

    vectorFromAngle = function(angle, length)
        return math.cos(angle / 180 * math.pi) * length, math.sin(angle / 180 * math.pi) * length
    end,

    spawnAtStation = function(station, obj)
        local x, y = station:getPosition()
        local angle = math.random(0, 360)
        local dx, dy = Util.vectorFromAngle(angle, 500)
        return obj:setPosition(x + dx, y + dy):setRotation(angle)
    end,

    --- copies a thing (table) recursive
    -- @ see http://lua-users.org/wiki/CopyTable
    deepCopy = function (orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
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

    mkString = function(table, separator, lastSeparator)
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
                local nextKey, nextValue = next(table)
                if k == lastIndex and lastSeparator ~= nil then
                    -- if last element
                    string = string .. lastSeparator .. value
                else
                    string = string .. separator .. value
                end
            end
        end

        return string
    end
}