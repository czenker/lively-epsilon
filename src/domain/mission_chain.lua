Mission = Mission or {}

--- A mission chain where all submissions have to be run in the specified order
--- @param self
--- @param ... Mission
--- @param config table
---   @field acceptCondition function gets `self` as arguments. should return `true` or `false` whether the mission can be accepted
---   @field onAccept function gets `self` as argument
---   @field onDecline function gets `self` as argument
---   @field onStart function gets `self` as argument
---   @field onSuccess function gets `self` as argument
---   @field onFailure function gets `self` as argument
---   @field onEnd function gets `self` as argument
Mission.chain = function(self, ...)
    local config = nil
    local subMissions = {}

    for _, arg in pairs({...}) do
        if Mission:isMission(arg) then
            if Mission:isSubMission(arg) then error("Submissions can not be part of other mission containers, but " .. arg:getId() " is already part of " .. arg:getParentMission():getId() .. ".", 2) end
            if arg:getState() ~= "new" then error("Expected all missions for mission chain, to be new, but " .. arg:getId() .. " is " .. arg:getState(), 2) end
            table.insert(subMissions, arg)
        elseif isTable(arg) then
            if not isNil(config) then
                error("Already got a config " .. typeInspect(config) .. ". Invalid argument " .. typeInspect(arg), 4)
            end
            config = arg
        else
            error("Invalid mission. Expected mission or config, but got " .. typeInspect(arg), 3)
        end
    end

    config = config or {}

    if not subMissions[1] then error("Expected at least one submission, but got 0", 2) end
    local mission = Mission:new(config)

    local currentMissionKey = 1
    local registerEventListeners

    registerEventListeners = function(subMission)
        subMission:addSuccessListener(function()
            currentMissionKey = currentMissionKey + 1
            if subMissions[currentMissionKey] ~= nil and mission:getState() == "started" then
                local nextMission = subMissions[currentMissionKey]
                registerEventListeners(nextMission)
                nextMission:accept()
                nextMission:start()
            elseif mission:getState() == "started" then
                mission:success()
            end
        end)
        subMission:addFailureListener(function()
            if mission:getState() == "started" then
                mission:fail()
            end
        end)
    end


    local parentAccept = mission.accept
    mission.accept = function(self)
        parentAccept(self)
        subMissions[1]:accept()
    end

    local parentStart = mission.start
    mission.start = function(self)
        parentStart(self)
        registerEventListeners(subMissions[1])
        subMissions[1]:start()
    end

    local parentSuccess = mission.success
    mission.success = function(self)
        parentSuccess(self)
        local currentMission = subMissions[currentMissionKey]
        if currentMission ~= nil and currentMission:getState() == "started" then
            currentMission:success()
        end
    end

    local parentFail = mission.fail
    mission.fail = function(self)
        parentFail(self)
        local currentMission = subMissions[currentMissionKey]
        if currentMission ~= nil and currentMission:getState() == "started" then
            currentMission:fail()
        end
    end

    mission.getCurrentMission = function()
        if mission:getState() == "started" then
            return subMissions[currentMissionKey]
        else
            return nil
        end
    end

    for _, subMission in pairs(subMissions) do
        subMission.getParentMission = function() return mission end
    end

    return mission
end