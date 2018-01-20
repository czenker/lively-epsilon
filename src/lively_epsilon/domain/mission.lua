Mission = Mission or {}

-- config:
--  * id           string
--  * onAccept     function
--  * onDecline    function
--  * onStart      function
--  * onSuccess    function
--  * onFailure    function
--  * onEnd        function

Mission.new = function(self, config)
    config = config or {}
    if not isTable(config) then
        error("Expected config to be a table, but " .. type(config) .. " given.", 2)
    end
    if not isNil(config.acceptCondition) and not isFunction(config.acceptCondition) then error("Expected config.acceptCondition to be a function, but " .. type(config.acceptCondition) .. " given.", 2) end
    if not isNil(config.onAccept) and not isFunction(config.onAccept) then error("Expected config.onAccept to be a function, but " .. type(config.onAccept) .. " given.", 2) end
    if not isNil(config.onDecline) and not isFunction(config.onDecline) then error("Expected config.onDecline to be a function, but " .. type(config.onDecline) .. " given.", 2) end
    if not isNil(config.onStart) and not isFunction(config.onStart) then error("Expected config.onStart to be a function, but " .. type(config.onStart) .. " given.", 2) end
    if not isNil(config.onSuccess) and not isFunction(config.onSuccess) then error("Expected config.onSuccess to be a function, but " .. type(config.onSuccess) .. " given.", 2) end
    if not isNil(config.onFailure) and not isFunction(config.onFailure) then error("Expected config.onFailure to be a function, but " .. type(config.onFailure) .. " given.", 2) end
    if not isNil(config.onEnd) and not isFunction(config.onEnd) then error("Expected config.onEnd to be a function, but " .. type(config.onEnd) .. " given.", 2) end

    local id = config.id or Util.randomUuid()

    local state = 0

    local mission = {

        -- !!! internal - please do not manipulate !!!
        getId = function(self) return id end,
        getState = function(self)
            if state == 0 then
                return "new"
            elseif state == 5 then
                return "accepted"
            elseif state == 10 then
                return "started"
            elseif state == 98 then
                return "declined"
            elseif state == 99 then
                return "failed"
            elseif state == 100 then
                return "successful"
            end
        end,
        canBeAccepted = function(self)
            if isFunction(config.acceptCondition) then
                local msg = config.acceptCondition(self)
                if isString(msg) then
                    return false, msg
                elseif msg == false then
                    return false
                else
                    if msg ~= true and not isNil(msg) then
                        logWarning("Expected acceptCondition callback to return a string or boolean, but got " .. type(msg) .. ". Assuming true.")
                    end
                end
            end
            return true
        end,
        accept = function(self)
            if state ~= 0 then
                error("Mission \"" .. self:getId() .. "\" can not be accepted, because it was already started.", 2)
            end
            local canBeAccepted, msg = self:canBeAccepted()
            if not canBeAccepted then
                local errorMsg = "Mission \"" .. self:getId() .. "\" can not be accepted, because its acceptCondition is false"
                if not isString(msg) then
                    errorMsg = errorMsg .. ": " .. msg
                end
                error(errorMsg, 2)
            end

            if isFunction(config.onAccept) then config.onAccept(self) end

            state = 5
        end,
        decline = function(self)
            if state ~= 0 then
                error("Mission \"" .. self:getId() .. "\" can not be declined, because it was already started.", 2)
            end
            if isFunction(config.onDecline) then config.onDecline(self) end
            state = 98
        end,
        start = function(self)
            if state ~= 5 then
                error("Mission \"" .. self:getId() .. "\" can not be started, because it was not accepted.", 2)
            end
            if isFunction(config.onStart) then config.onStart(self) end
            state = 10
        end,
        fail = function(self)
            if state ~= 10 then
                error("Mission \"" .. self:getId() .. "\" can not fail, because it is not currently running.", 2)
            end

            if isFunction(config.onFail) then config.onFail(self) end
            if isFunction(config.onEnd) then config.onEnd(self) end
            state = 99
        end,
        success = function(self)
            if state ~= 10 then
                error("Mission \"" .. self:getId() .. "\" can not succeed, because it is not currently running.", 2)
            end

            if isFunction(config.onSuccess) then config.onSuccess(self) end
            if isFunction(config.onEnd) then config.onEnd(self) end
            state = 100
        end,
    }

    return mission
end

Mission.isMission = function(mission)
    return isTable(mission) and
            isFunction(mission.getId) and
            isFunction(mission.canBeAccepted) and
            isFunction(mission.accept) and
            isFunction(mission.decline) and
            isFunction(mission.start) and
            isFunction(mission.success) and
            isFunction(mission.fail) and
            isFunction(mission.getState)
end

setmetatable(Mission,{
    __index = Generic
})