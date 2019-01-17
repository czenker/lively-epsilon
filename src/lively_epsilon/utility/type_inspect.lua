function typeInspect(thing)
    local t = type(thing)
    if t == "nil" then
        return "<nil>"
    elseif t == "boolean" then
        return "<bool>" .. (thing and "true" or "false")
    elseif t == "number" then
        return "<number>" .. thing
    elseif t == "string" then
        if thing:len() > 30 then
            thing = thing:sub(1, 30) .. "..."
        end
        return "<string>\"" .. thing .. "\""
    elseif t == "table" then
        if thing.typeName ~= nil then
            local s = "<" .. thing.typeName .. ">"
            if isFunction(thing.isValid) and thing:isValid() and isFunction(thing.getCallSign) then
                s = s .. "\"" .. thing:getCallSign() .. "\""
            end
            return s
        else
            return string.format("<table>(size: %d)", Util.size(thing))
        end
    else
        return "<" .. t .. ">"
    end
end