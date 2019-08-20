Mission = Mission or {}

local eventHandler = EventHandler:new({allowedEvents = {
    "onCreation",
    "onAccept",
    "onDecline",
    "onStart",
    "onSuccess",
    "onFailure",
    "onEnd",
}})

--- A mission
--- @param self
--- @param config table
---   @field acceptCondition function gets `self` as arguments. should return `true` or `false` whether the mission can be accepted
---   @field onAccept function gets `self` as argument
---   @field onDecline function gets `self` as argument
---   @field onStart function gets `self` as argument
---   @field onSuccess function gets `self` as argument
---   @field onFailure function gets `self` as argument
---   @field onEnd function gets `self` as argument
Mission.new = function(self, config)
    config = config or {}
    if not isTable(config) then
        error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2)
    end
    if not isNil(config.acceptCondition) and not isFunction(config.acceptCondition) then error("Expected config.acceptCondition to be a function, but " .. typeInspect(config.acceptCondition) .. " given.", 2) end
    if not isNil(config.onAccept) and not isFunction(config.onAccept) then error("Expected config.onAccept to be a function, but " .. typeInspect(config.onAccept) .. " given.", 2) end
    if not isNil(config.onDecline) and not isFunction(config.onDecline) then error("Expected config.onDecline to be a function, but " .. typeInspect(config.onDecline) .. " given.", 2) end
    if not isNil(config.onStart) and not isFunction(config.onStart) then error("Expected config.onStart to be a function, but " .. typeInspect(config.onStart) .. " given.", 2) end
    if not isNil(config.onSuccess) and not isFunction(config.onSuccess) then error("Expected config.onSuccess to be a function, but " .. typeInspect(config.onSuccess) .. " given.", 2) end
    if not isNil(config.onFailure) and not isFunction(config.onFailure) then error("Expected config.onFailure to be a function, but " .. typeInspect(config.onFailure) .. " given.", 2) end
    if not isNil(config.onEnd) and not isFunction(config.onEnd) then error("Expected config.onEnd to be a function, but " .. typeInspect(config.onEnd) .. " given.", 2) end

    local id = config.id or Util.randomUuid()

    local state = 0

    local mission = {

        --- The unique id of the mission
        --- @internal
        --- @param self
        --- @return string
        getId = function(self) return id end,
        --- Get the state of the mission.
        --- @param self
        --- @return string
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
        ---checks if the mission can be accepted
        ---@param self
        canBeAccepted = function(self)
            if isFunction(config.acceptCondition) then
                local msg = config.acceptCondition(self)
                if isString(msg) then
                    return false, msg
                elseif msg == false then
                    return false
                else
                    if msg ~= true and not isNil(msg) then
                        logWarning("Expected acceptCondition callback to return a string or boolean, but got " .. typeInspect(msg) .. ". Assuming true.")
                    end
                end
            end
            return true
        end,
        --- mark the mission as accepted
        ---@param self
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
            eventHandler:fire("onAccept", self)

            state = 5
        end,
        ---mark the mission as declined
        ---@param self
        decline = function(self)
            if state ~= 0 then
                error("Mission \"" .. self:getId() .. "\" can not be declined, because it was already started.", 2)
            end
            if isFunction(config.onDecline) then config.onDecline(self) end
            eventHandler:fire("onDecline", self)
            state = 98
        end,
        ---mark the mission as started
        ---@param self
        start = function(self)
            if state ~= 5 then
                error("Mission \"" .. self:getId() .. "\" can not be started, because it was not accepted.", 2)
            end
            if isFunction(config.onStart) then config.onStart(self) end
            eventHandler:fire("onStart", self)
            state = 10
        end,
        ---mark the mission as failed
        ---@param self
        fail = function(self)
            if state ~= 10 then
                error("Mission \"" .. self:getId() .. "\" can not fail, because it is not currently running.", 2)
            end

            if isFunction(config.onFailure) then config.onFailure(self) end
            eventHandler:fire("onFailure", self)
            if isFunction(config.onEnd) then config.onEnd(self) end
            eventHandler:fire("onEnd", self)
            state = 99
        end,
        ---mark the mission as successful
        ---@param self
        success = function(self)
            if state ~= 10 then
                error("Mission \"" .. self:getId() .. "\" can not succeed, because it is not currently running.", 2)
            end

            if isFunction(config.onSuccess) then config.onSuccess(self) end
            eventHandler:fire("onSuccess", self)
            if isFunction(config.onEnd) then config.onEnd(self) end
            eventHandler:fire("onEnd", self)
            state = 100
        end,
    }

    eventHandler:fire("onCreation", mission)

    return mission
end

--- check if a thing is a `Mission`
--- @param self
--- @param mission any
--- @return boolean
Mission.isMission = function(self, mission)
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

--- Event listener if any mission is created
--- @param self
--- @param handler function gets `self` and the `mission` as arguments
--- @param priority number
Mission.registerMissionCreationListener = function(self, handler, priority)
    eventHandler:register("onCreation", handler, priority)
end

--- Event listener if any mission is accepted
--- @param self
--- @param handler function gets `self` and the `mission` as arguments
--- @param priority number
Mission.registerMissionAcceptListener = function(self, handler, priority)
    eventHandler:register("onAccept", handler, priority)
end

--- Event listener if any mission is declined
--- @param self
--- @param handler function gets `self` and the `mission` as arguments
--- @param priority number
Mission.registerMissionDeclineListener = function(self, handler, priority)
    eventHandler:register("onDecline", handler, priority)
end

--- Event listener if any mission is started
--- @param self
--- @param handler function gets `self` and the `mission` as arguments
--- @param priority number
Mission.registerMissionStartListener = function(self, handler, priority)
    eventHandler:register("onStart", handler, priority)
end

--- Event listener if any mission is successful
--- @param self
--- @param handler function gets `self` and the `mission` as arguments
--- @param priority number
Mission.registerMissionSuccessListener = function(self, handler, priority)
    eventHandler:register("onSuccess", handler, priority)
end

--- Event listener if any mission failed
--- @param self
--- @param handler function gets `self` and the `mission` as arguments
--- @param priority number
Mission.registerMissionFailureListener = function(self, handler, priority)
    eventHandler:register("onFailure", handler, priority)
end

--- Event listener if any mission ended
--- @param self
--- @param handler function gets `self` and the `mission` as arguments
--- @param priority number
Mission.registerMissionEndListener = function(self, handler, priority)
    eventHandler:register("onEnd", handler, priority)
end

setmetatable(Mission,{
    __index = Generic
})